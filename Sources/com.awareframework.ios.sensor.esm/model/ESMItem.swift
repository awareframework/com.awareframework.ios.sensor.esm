import Foundation

/// A single ESM question parsed from the AWARE ESM JSON format.
public struct ESMItem: Codable, Equatable, Sendable {

    // MARK: Common fields

    public var esmType: Int
    public var esmTitle: String?
    public var esmInstructions: String?
    public var esmSubmit: String?
    public var esmTrigger: String?
    public var esmExpirationThreshold: Int?
    public var esmNa: Int?

    // MARK: Radio (type 2)

    public var esmRadios: [String]?

    // MARK: Checkbox (type 3)

    public var esmCheckboxes: [String]?

    // MARK: Likert Scale (type 4)

    public var esmLikertMax: Int?
    public var esmLikertMaxLabel: String?
    public var esmLikertMinLabel: String?
    public var esmLikertStep: Int?

    // MARK: Quick Answer (type 5)

    public var esmQuickAnswers: [String]?

    // MARK: Scale/Slider (type 6)

    public var esmScaleMax: Int?
    public var esmScaleMin: Int?
    public var esmScaleStart: Int?
    public var esmScaleMaxLabel: String?
    public var esmScaleMinLabel: String?
    public var esmScaleStep: Int?

    // MARK: Web (type 10)

    public var esmUrl: String?

    // MARK: Picture / Video (type 14, 16)

    public var esmCamera: Int?

    // MARK: CodingKeys — maps Swift camelCase to JSON snake_case

    public enum CodingKeys: String, CodingKey {
        case esmType                = "esm_type"
        case esmTitle               = "esm_title"
        case esmInstructions        = "esm_instructions"
        case esmSubmit              = "esm_submit"
        case esmTrigger             = "esm_trigger"
        case esmExpirationThreshold = "esm_expiration_threshold"
        case esmNa                  = "esm_na"
        case esmRadios              = "esm_radios"
        case esmCheckboxes          = "esm_checkboxes"
        case esmLikertMax           = "esm_likert_max"
        case esmLikertMaxLabel      = "esm_likert_max_label"
        case esmLikertMinLabel      = "esm_likert_min_label"
        case esmLikertStep          = "esm_likert_step"
        case esmQuickAnswers        = "esm_quick_answers"
        case esmScaleMax            = "esm_scale_max"
        case esmScaleMin            = "esm_scale_min"
        case esmScaleStart          = "esm_scale_start"
        case esmScaleMaxLabel       = "esm_scale_max_label"
        case esmScaleMinLabel       = "esm_scale_min_label"
        case esmScaleStep           = "esm_scale_step"
        case esmUrl                 = "esm_url"
        case esmCamera              = "esm_camera"
    }

    // MARK: Convenience

    public var esmTypeEnum: ESMType? {
        ESMType(rawValue: esmType)
    }

    public init(esmType: Int, esmTitle: String? = nil, esmInstructions: String? = nil,
                esmSubmit: String? = nil, esmTrigger: String? = nil) {
        self.esmType = esmType
        self.esmTitle = esmTitle
        self.esmInstructions = esmInstructions
        self.esmSubmit = esmSubmit
        self.esmTrigger = esmTrigger
    }
}

/// Wrapper matching the JSON structure `{ "esm": { ... } }`.
public struct ESMItemWrapper: Codable, Equatable, Sendable {
    public var esm: ESMItem

    public init(esm: ESMItem) {
        self.esm = esm
    }
}
