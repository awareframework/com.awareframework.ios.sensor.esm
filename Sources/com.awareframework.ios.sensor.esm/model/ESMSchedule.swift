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
///     "notification_title": "Survey",
///     "notification_body": "Please answer a few questions",
///     "esms": [ { "esm": { ... } } ]
///   }
/// ]
/// ```
public struct ESMSchedule: Codable, Equatable, Sendable, Identifiable {

    public var id: String { scheduleId }

    public var scheduleId: String
    public var hours: [Int]
    public var startDate: String
    public var endDate: String
    public var expiration: Int
    public var randomize: Int
    public var notificationTitle: String
    public var notificationBody: String
    public var esms: [ESMItemWrapper]
    public var interface: Int?

    public enum CodingKeys: String, CodingKey {
        case scheduleId       = "schedule_id"
        case hours            = "hours"
        case startDate        = "start_date"
        case endDate          = "end_date"
        case expiration       = "expiration"
        case randomize        = "randomize"
        case notificationTitle = "notification_title"
        case notificationBody  = "notification_body"
        case esms             = "esms"
        case interface        = "interface"
    }

    public init(
        scheduleId: String,
        hours: [Int],
        startDate: String,
        endDate: String,
        expiration: Int = 0,
        randomize: Int = 0,
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
        self.notificationTitle = notificationTitle
        self.notificationBody = notificationBody
        self.esms = esms
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
