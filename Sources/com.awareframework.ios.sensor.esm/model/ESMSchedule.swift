import Foundation

/// A complete ESM schedule parsed from the AWARE ESM JSON format.
///
/// Top-level JSON structure:
/// ```json
/// [
///   {
///     "schedule_id": "schedule1",
///     "hours": [9, 17],
///     "start_date": "01-01-2024",
///     "end_date": "12-31-2024",
///     "expiration": 30,
///     "randomize": 10,
///     "weekdays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
///     "notification_title": "Survey",
///     "notification_body": "Please answer a few questions",
///     "esms": [ { "esm": { ... } } ]
///   }
/// ]
/// ```
/// Omit `weekdays` (or set to `null`) to fire on all days of the week.
public struct ESMSchedule: Codable, Equatable, Sendable, Identifiable {

    public var id: String { scheduleId }

    public var scheduleId: String
    public var hours: [Int]
    public var startDate: String
    public var endDate: String
    public var expiration: Int
    public var randomize: Int
    /// Days of the week on which this schedule fires.
    /// Accepted values: "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday".
    /// `nil` means all days.
    public var weekdays: [String]?
    public var notificationTitle: String
    public var notificationBody: String
    public var esms: [ESMItemWrapper]
    public var interface: Int?

    public enum CodingKeys: String, CodingKey {
        case scheduleId        = "schedule_id"
        case hours             = "hours"
        case startDate         = "start_date"
        case endDate           = "end_date"
        case expiration        = "expiration"
        case randomize         = "randomize"
        case weekdays          = "weekdays"
        case notificationTitle = "notification_title"
        case notificationBody  = "notification_body"
        case esms              = "esms"
        case interface         = "interface"
    }

    public init(
        scheduleId: String,
        hours: [Int],
        startDate: String,
        endDate: String,
        expiration: Int = 0,
        randomize: Int = 0,
        weekdays: [String]? = nil,
        notificationTitle: String,
        notificationBody: String,
        esms: [ESMItemWrapper]
    ) {
        self.scheduleId = scheduleId
        self.hours = hours
        self.startDate = startDate
        self.endDate = endDate
        self.expiration = expiration
        self.randomize = randomize
        self.weekdays = weekdays
        self.notificationTitle = notificationTitle
        self.notificationBody = notificationBody
        self.esms = esms
    }

    // MARK: - Weekday helpers

    /// Maps weekday name strings to iOS `Calendar.weekday` component values (1 = Sunday … 7 = Saturday).
    private static let weekdayMap: [String: Int] = [
        "Sunday": 1, "Monday": 2, "Tuesday": 3, "Wednesday": 4,
        "Thursday": 5, "Friday": 6, "Saturday": 7
    ]

    /// Returns the set of `Calendar.weekday` integers this schedule should fire on,
    /// or `nil` when the schedule fires every day.
    public var allowedWeekdays: Set<Int>? {
        guard let weekdays, !weekdays.isEmpty else { return nil }
        let mapped = weekdays.compactMap { ESMSchedule.weekdayMap[$0] }
        return mapped.isEmpty ? nil : Set(mapped)
    }

    // MARK: - Parsing

    public static func parse(from jsonString: String) throws -> [ESMSchedule] {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid UTF-8 string"))
        }
        return try parse(from: data)
    }

    public static func parse(from data: Data) throws -> [ESMSchedule] {
        return try JSONDecoder().decode([ESMSchedule].self, from: data)
    }

    public static func parse(from url: URL) throws -> [ESMSchedule] {
        let data = try Data(contentsOf: url)
        return try parse(from: data)
    }

    // MARK: - Date helpers

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd-yyyy"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    public var parsedStartDate: Date? {
        ESMSchedule.dateFormatter.date(from: startDate)
    }

    public var parsedEndDate: Date? {
        ESMSchedule.dateFormatter.date(from: endDate)
    }

    public var isActive: Bool {
        let now = Date()
        guard let start = parsedStartDate, let end = parsedEndDate else { return false }
        return now >= start && now <= end
    }
}
