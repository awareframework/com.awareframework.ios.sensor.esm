import Foundation

public enum ESMType: Int, Codable, CaseIterable, Sendable {
    case freeText    = 1
    case radio       = 2
    case checkbox    = 3
    case likert      = 4
    case quickAnswer = 5
    case scale       = 6
    case dateTime    = 7
    case pam         = 8
    case numeric     = 9
    case web         = 10
    case datePicker  = 11
    case clock       = 13
    case picture     = 14
    case audio       = 15
    case video       = 16

    public var displayName: String {
        switch self {
        case .freeText:    return "Free Text"
        case .radio:       return "Radio"
        case .checkbox:    return "Checkbox"
        case .likert:      return "Likert Scale"
        case .quickAnswer: return "Quick Answer"
        case .scale:       return "Scale"
        case .dateTime:    return "DateTime"
        case .pam:         return "PAM"
        case .numeric:     return "Numeric"
        case .web:         return "Web"
        case .datePicker:  return "Date Picker"
        case .clock:       return "Clock"
        case .picture:     return "Picture"
        case .audio:       return "Audio"
        case .video:       return "Video"
        }
    }
}

public enum ESMStatus: Int, Sendable {
    case new       = 0
    case answered  = 1
    case dismissed = 2
    case expired   = 3
}
