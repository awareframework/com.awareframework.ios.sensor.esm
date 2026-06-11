import Foundation
import UserNotifications

/// Manages ESM schedule persistence, local notification scheduling, and active-schedule queries.
///
/// Typical usage:
/// ```swift
/// let json = try String(contentsOf: myURL)
/// try ESMScheduleManager.shared.loadSchedules(from: json)
/// let pending = ESMScheduleManager.shared.activeSchedules()
/// ```
public final class ESMScheduleManager: NSObject {

    public static let shared = ESMScheduleManager()

    // Each ESM notification carries this category so we can identify and cancel ESM-only requests.
    public static let notificationCategoryIdentifier = "com.awareframework.ios.sensor.esm.notification"

    // Notification action identifiers
    public static let actionAnswer  = "com.awareframework.ios.sensor.esm.action.answer"
    public static let actionDismiss = "com.awareframework.ios.sensor.esm.action.dismiss"

    // UserDefaults key for persisting loaded schedules
    private let schedulesDefaultsKey = "com.awareframework.ios.sensor.esm.schedules"

    // iOS caps pending notifications at 64; leave headroom for other app notifications.
    private let maxScheduledNotifications = 56

    private let notificationCenter = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        registerNotificationCategory()
    }

    // MARK: - Public API

    /// Load and activate schedules from a JSON string.
    public func loadSchedules(from jsonString: String) throws {
        let schedules = try ESMSchedule.parse(from: jsonString)
        activateSchedules(schedules)
    }

    /// Load and activate schedules from raw JSON data.
    public func loadSchedules(from data: Data) throws {
        let schedules = try ESMSchedule.parse(from: data)
        activateSchedules(schedules)
    }

    /// Load and activate schedules from a local file URL.
    public func loadSchedules(from url: URL) throws {
        let schedules = try ESMSchedule.parse(from: url)
        activateSchedules(schedules)
    }

    /// Replace current schedules with the given array and reschedule notifications.
    public func activateSchedules(_ schedules: [ESMSchedule]) {
        persist(schedules: schedules)
        cancelAllESMNotifications()
        for schedule in schedules {
            guard schedule.isActive else { continue }
            scheduleNotifications(for: schedule)
        }
    }

    /// Returns all currently active schedules (within start/end date window).
    public func activeSchedules() -> [ESMSchedule] {
        loadedSchedules().filter { $0.isActive }
    }

    /// Returns all persisted schedules regardless of date range.
    public func loadedSchedules() -> [ESMSchedule] {
        guard let data = UserDefaults.standard.data(forKey: schedulesDefaultsKey),
              let schedules = try? JSONDecoder().decode([ESMSchedule].self, from: data) else {
            return []
        }
        return schedules
    }

    /// Remove all persisted schedules and cancel all pending ESM notifications.
    public func clearSchedules() {
        UserDefaults.standard.removeObject(forKey: schedulesDefaultsKey)
        cancelAllESMNotifications()
    }

    /// Request notification permission. Call early in the app lifecycle.
    public func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Notification Scheduling

    private func scheduleNotifications(for schedule: ESMSchedule) {
        guard let startDate = schedule.parsedStartDate,
              let endDate   = schedule.parsedEndDate else { return }

        let calendar  = Calendar.current
        let today     = Date()
        var cursor    = max(today, startDate)
        var scheduled = 0

        while cursor <= endDate && scheduled < maxScheduledNotifications {
            for hour in schedule.hours {
                guard scheduled < maxScheduledNotifications else { break }

                var comps   = calendar.dateComponents([.year, .month, .day], from: cursor)
                comps.hour   = hour
                comps.minute = 0
                comps.second = 0

                guard var fireDate = calendar.date(from: comps) else { continue }

                // Apply per-schedule randomization (±minutes)
                if schedule.randomize > 0 {
                    let offset = Int.random(in: -schedule.randomize...schedule.randomize)
                    fireDate   = fireDate.addingTimeInterval(TimeInterval(offset * 60))
                }

                guard fireDate > today else { continue }

                let id = notificationIdentifier(scheduleId: schedule.scheduleId, fireDate: fireDate)
                enqueue(request: makeRequest(schedule: schedule, fireDate: fireDate, identifier: id))
                scheduled += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
    }

    private func makeRequest(schedule: ESMSchedule, fireDate: Date, identifier: String) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title              = schedule.notificationTitle
        content.body               = schedule.notificationBody
        content.sound              = .default
        content.categoryIdentifier = ESMScheduleManager.notificationCategoryIdentifier
        content.userInfo           = [
            "scheduleId":        schedule.scheduleId,
            "notificationTime":  Int64(fireDate.timeIntervalSince1970 * 1000),
        ]

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func enqueue(request: UNNotificationRequest) {
        notificationCenter.add(request) { error in
            if let error { print("ESMScheduleManager: schedule error:", error) }
        }
    }

    private func cancelAllESMNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.content.categoryIdentifier == ESMScheduleManager.notificationCategoryIdentifier }
                .map    { $0.identifier }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Expiration check

    /// Returns the ESMSchedule matching a notification's userInfo, if still within its expiration window.
    public func schedule(from userInfo: [AnyHashable: Any]) -> ESMSchedule? {
        guard let scheduleId = userInfo["scheduleId"] as? String else { return nil }
        let schedule = loadedSchedules().first { $0.scheduleId == scheduleId }
        guard let s = schedule, s.isActive else { return nil }

        // Check expiration threshold (minutes after notification fired)
        if s.expiration > 0,
           let notifTime = userInfo["notificationTime"] as? Int64 {
            let elapsed = (Date().timeIntervalSince1970 * 1000 - Double(notifTime)) / 60_000
            if elapsed > Double(s.expiration) { return nil }
        }
        return s
    }

    // MARK: - Helpers

    private func persist(schedules: [ESMSchedule]) {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: schedulesDefaultsKey)
        }
    }

    private func notificationIdentifier(scheduleId: String, fireDate: Date) -> String {
        "\(ESMScheduleManager.notificationCategoryIdentifier).\(scheduleId).\(Int(fireDate.timeIntervalSince1970))"
    }

    private func registerNotificationCategory() {
        let answerAction = UNNotificationAction(
            identifier: ESMScheduleManager.actionAnswer,
            title: "Answer",
            options: [.foreground]
        )
        let dismissAction = UNNotificationAction(
            identifier: ESMScheduleManager.actionDismiss,
            title: "Dismiss",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: ESMScheduleManager.notificationCategoryIdentifier,
            actions: [answerAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([category])
    }
}
