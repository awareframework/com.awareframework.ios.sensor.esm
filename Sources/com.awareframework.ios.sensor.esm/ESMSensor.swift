import Foundation
import com_awareframework_ios_core

// MARK: - Notification Names

extension Notification.Name {
    public static let actionAwareESM              = Notification.Name(ESMSensor.ACTION_AWARE_ESM)
    public static let actionAwareESMStart         = Notification.Name(ESMSensor.ACTION_AWARE_ESM_START)
    public static let actionAwareESMStop          = Notification.Name(ESMSensor.ACTION_AWARE_ESM_STOP)
    public static let actionAwareESMAnswered      = Notification.Name(ESMSensor.ACTION_AWARE_ESM_ANSWERED)
    public static let actionAwareESMDismissed     = Notification.Name(ESMSensor.ACTION_AWARE_ESM_DISMISSED)
    public static let actionAwareESMExpired       = Notification.Name(ESMSensor.ACTION_AWARE_ESM_EXPIRED)
    public static let actionAwareESMSync          = Notification.Name(ESMSensor.ACTION_AWARE_ESM_SYNC)
    public static let actionAwareESMSyncCompletion = Notification.Name(ESMSensor.ACTION_AWARE_ESM_SYNC_COMPLETION)
}

// MARK: - Observer protocol

public protocol ESMSensorObserver {
    func onESMAnswered(data: ESMData)
    func onESMDismissed(data: ESMData)
    func onESMExpired(data: ESMData)
    func onScheduleLoaded(schedules: [ESMSchedule])
}

// MARK: - ESMSensor

public final class ESMSensor: AwareSensor {

    // MARK: Action keys

    public static let ACTION_AWARE_ESM               = "com.awareframework.ios.sensor.esm"
    public static let ACTION_AWARE_ESM_START         = "com.awareframework.ios.sensor.esm.ACTION_START"
    public static let ACTION_AWARE_ESM_STOP          = "com.awareframework.ios.sensor.esm.ACTION_STOP"
    public static let ACTION_AWARE_ESM_ANSWERED      = "com.awareframework.ios.sensor.esm.ACTION_ANSWERED"
    public static let ACTION_AWARE_ESM_DISMISSED     = "com.awareframework.ios.sensor.esm.ACTION_DISMISSED"
    public static let ACTION_AWARE_ESM_EXPIRED       = "com.awareframework.ios.sensor.esm.ACTION_EXPIRED"
    public static let ACTION_AWARE_ESM_SYNC          = "com.awareframework.ios.sensor.esm.ACTION_SYNC"
    public static let ACTION_AWARE_ESM_SYNC_COMPLETION = "com.awareframework.ios.sensor.esm.ACTION_SYNC_COMPLETION"
    public static let EXTRA_STATUS                   = "status"
    public static let EXTRA_ERROR                    = "error"

    public static let TAG = "com.awareframework.ios.sensor.esm"

    // MARK: Config

    public class Config: SensorConfig {
        public var sensorObserver: ESMSensorObserver?

        public override init() { super.init() }

        public func apply(closure: (_ config: ESMSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }

    // MARK: Properties

    public var CONFIG = ESMSensor.Config()
    private var esmSubSensor: ESMSubSensor?

    // MARK: Init

    public init(_ config: ESMSensor.Config = ESMSensor.Config()) {
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        super.syncConfig = DbSyncConfig().apply { syncConfig in
            syncConfig.serverType = config.serverType
            syncConfig.studyNumber = config.studyNumber
            syncConfig.studyKey = config.studyKey
            syncConfig.debug = config.debug
            syncConfig.batchSize = 1000
        }
        self.esmSubSensor = ESMSubSensor(config)
    }

    // MARK: AwareSensor overrides

    public override func start() {
        ESMScheduleManager.shared.requestPermission { granted in
            if self.CONFIG.debug {
                print(ESMSensor.TAG, "Notification permission:", granted ? "granted" : "denied")
            }
        }
        notificationCenter.post(name: .actionAwareESMStart, object: self)
    }

    public override func stop() {
        notificationCenter.post(name: .actionAwareESMStop, object: self)
    }

    public override func sync(force: Bool = false) {
        notificationCenter.post(name: .actionAwareESMSync, object: self)
        esmSubSensor?.applySyncSettings(
            from: CONFIG,
            parentSyncConfig: syncConfig,
            completionHandler: { [weak self] status, error in
                guard let self else { return }
                var userInfo: [String: Any] = [ESMSensor.EXTRA_STATUS: status]
                if let error {
                    userInfo[ESMSensor.EXTRA_ERROR] = error
                }
                self.notificationCenter.post(
                    name: .actionAwareESMSyncCompletion,
                    object: self,
                    userInfo: userInfo
                )
            }
        )
        esmSubSensor?.sync(force: force)
    }

    public override func set(label: String) {
        CONFIG.label = label
    }

    // MARK: Schedule loading

    /// Load ESM schedules from a JSON string and schedule local notifications.
    public func loadSchedules(from jsonString: String) throws {
        let schedules = try ESMSchedule.parse(from: jsonString)
        ESMScheduleManager.shared.activateSchedules(schedules)
        CONFIG.sensorObserver?.onScheduleLoaded(schedules: schedules)
        if CONFIG.debug {
            print(ESMSensor.TAG, "Loaded \(schedules.count) schedule(s)")
        }
    }

    /// Load ESM schedules from raw JSON data and schedule local notifications.
    public func loadSchedules(from data: Data) throws {
        let schedules = try ESMSchedule.parse(from: data)
        ESMScheduleManager.shared.activateSchedules(schedules)
        CONFIG.sensorObserver?.onScheduleLoaded(schedules: schedules)
    }

    /// Load ESM schedules from a local JSON file and schedule local notifications.
    public func loadSchedules(from url: URL) throws {
        let schedules = try ESMSchedule.parse(from: url)
        ESMScheduleManager.shared.activateSchedules(schedules)
        CONFIG.sensorObserver?.onScheduleLoaded(schedules: schedules)
    }

    // MARK: Responding to ESMs

    /// Save a user's answer for one ESM question.
    ///
    /// - Parameters:
    ///   - item: The ESMItem that was answered.
    ///   - scheduleId: The parent schedule's identifier.
    ///   - answer: Encoded answer string (plain value or JSON array/object for multi-select).
    ///   - notificationTime: Milliseconds since epoch when the notification fired.
    public func submitAnswer(
        item: ESMItem,
        scheduleId: String,
        answer: String,
        notificationTime: Int64 = 0
    ) {
        let now  = Int64(Date().timeIntervalSince1970 * 1000)
        let data = ESMData(
            timestamp:           now,
            scheduleId:          scheduleId,
            esmTrigger:          item.esmTrigger ?? "",
            esmType:             item.esmType,
            esmTitle:            item.esmTitle ?? "",
            esmInstructions:     item.esmInstructions ?? "",
            esmAnswer:           answer,
            esmAnswerTime:       now,
            esmStatus:           ESMStatus.answered.rawValue,
            esmNotificationTime: notificationTime
        )
        save(data)
        CONFIG.sensorObserver?.onESMAnswered(data: data)
        notificationCenter.post(name: .actionAwareESMAnswered, object: self, userInfo: ["data": data])
    }

    /// Record that the user dismissed an ESM question without answering.
    public func dismissESM(
        item: ESMItem,
        scheduleId: String,
        notificationTime: Int64 = 0
    ) {
        let now  = Int64(Date().timeIntervalSince1970 * 1000)
        let data = ESMData(
            timestamp:           now,
            scheduleId:          scheduleId,
            esmTrigger:          item.esmTrigger ?? "",
            esmType:             item.esmType,
            esmTitle:            item.esmTitle ?? "",
            esmInstructions:     item.esmInstructions ?? "",
            esmStatus:           ESMStatus.dismissed.rawValue,
            esmNotificationTime: notificationTime
        )
        save(data)
        CONFIG.sensorObserver?.onESMDismissed(data: data)
        notificationCenter.post(name: .actionAwareESMDismissed, object: self, userInfo: ["data": data])
    }

    /// Record that an ESM question expired before the user responded.
    public func expireESM(
        item: ESMItem,
        scheduleId: String,
        notificationTime: Int64 = 0
    ) {
        let now  = Int64(Date().timeIntervalSince1970 * 1000)
        let data = ESMData(
            timestamp:           now,
            scheduleId:          scheduleId,
            esmTrigger:          item.esmTrigger ?? "",
            esmType:             item.esmType,
            esmTitle:            item.esmTitle ?? "",
            esmInstructions:     item.esmInstructions ?? "",
            esmStatus:           ESMStatus.expired.rawValue,
            esmNotificationTime: notificationTime
        )
        save(data)
        CONFIG.sensorObserver?.onESMExpired(data: data)
        notificationCenter.post(name: .actionAwareESMExpired, object: self, userInfo: ["data": data])
    }

    // MARK: Private

    private func save(_ data: ESMData) {
        esmSubSensor?.dbEngine?.save([data])
    }
}
