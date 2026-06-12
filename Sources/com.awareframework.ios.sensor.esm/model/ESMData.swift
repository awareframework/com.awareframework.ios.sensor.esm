import Foundation
import GRDB
import com_awareframework_ios_core

/// Persisted record for a single ESM question response.
public struct ESMData: BaseDbModelSQLite {

    // MARK: BaseDbModelSQLite

    public var id: Int64?
    public var timestamp: Int64
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1
    public var label: String = ""

    // MARK: ESM-specific

    public var scheduleId: String
    public var esmTrigger: String
    public var esmType: Int
    public var esmTitle: String
    public var esmInstructions: String
    /// JSON-encoded answer string (plain string for simple types, JSON array/object for complex ones).
    public var esmAnswer: String
    public var esmAnswerTime: Int64
    /// See ESMStatus enum: 0=new, 1=answered, 2=dismissed, 3=expired.
    public var esmStatus: Int
    public var esmNotificationTime: Int64

    public static let databaseTableName = "ios_esm"

    // MARK: Init

    public init(
        timestamp: Int64,
        scheduleId: String,
        esmTrigger: String,
        esmType: Int,
        esmTitle: String = "",
        esmInstructions: String = "",
        esmAnswer: String = "",
        esmAnswerTime: Int64 = 0,
        esmStatus: Int = 0,
        esmNotificationTime: Int64 = 0
    ) {
        self.timestamp = timestamp
        self.scheduleId = scheduleId
        self.esmTrigger = esmTrigger
        self.esmType = esmType
        self.esmTitle = esmTitle
        self.esmInstructions = esmInstructions
        self.esmAnswer = esmAnswer
        self.esmAnswerTime = esmAnswerTime
        self.esmStatus = esmStatus
        self.esmNotificationTime = esmNotificationTime
    }

    public init(_ dict: [String: Any]) {
        self.timestamp          = dict["timestamp"] as? Int64 ?? 0
        self.deviceId           = dict["deviceId"] as? String ?? ""
        self.scheduleId         = dict["scheduleId"] as? String ?? ""
        self.esmTrigger         = dict["esmTrigger"] as? String ?? ""
        self.esmType            = dict["esmType"] as? Int ?? 0
        self.esmTitle           = dict["esmTitle"] as? String ?? ""
        self.esmInstructions    = dict["esmInstructions"] as? String ?? ""
        self.esmAnswer          = dict["esmAnswer"] as? String ?? ""
        self.esmAnswerTime      = dict["esmAnswerTime"] as? Int64 ?? 0
        self.esmStatus          = dict["esmStatus"] as? Int ?? 0
        self.esmNotificationTime = dict["esmNotificationTime"] as? Int64 ?? 0
    }

    // MARK: Table creation

    public static func createTable(queue: DatabaseQueue) {
        do {
            try queue.write { db in
                try db.create(table: ESMData.databaseTableName, ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("deviceId", .text).notNull()
                    t.column("timestamp", .integer).notNull()
                    t.column("timezone", .integer).notNull()
                    t.column("os", .text).notNull()
                    t.column("jsonVersion", .integer).notNull()
                    t.column("label", .text).notNull()
                    t.column("scheduleId", .text).notNull()
                    t.column("esmTrigger", .text).notNull()
                    t.column("esmType", .integer).notNull()
                    t.column("esmTitle", .text).notNull()
                    t.column("esmInstructions", .text).notNull()
                    t.column("esmAnswer", .text).notNull()
                    t.column("esmAnswerTime", .integer).notNull()
                    t.column("esmStatus", .integer).notNull()
                    t.column("esmNotificationTime", .integer).notNull()
                }
            }
        } catch {
            print("ESMData: createTable error:", error)
        }
    }

    // MARK: Serialization

    public func toDictionary() -> [String: Any] {
        return [
            "id":                  id ?? -1,
            "timestamp":           timestamp,
            "deviceId":            deviceId,
            "timezone":            timezone,
            "os":                  os,
            "jsonVersion":         jsonVersion,
            "label":               label,
            "scheduleId":          scheduleId,
            "esmTrigger":          esmTrigger,
            "esmType":             esmType,
            "esmTitle":            esmTitle,
            "esmInstructions":     esmInstructions,
            "esmAnswer":           esmAnswer,
            "esmAnswerTime":       esmAnswerTime,
            "esmStatus":           esmStatus,
            "esmNotificationTime": esmNotificationTime,
        ]
    }
}
