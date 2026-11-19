import Foundation

/// A single ESM question parsed from the AWARE ESM JSON format.
public struct ESMItem: Codable, Equatable, Sendable {

    // MARK: Common fields

    public var esmType: Int
    public var esmTitle: String?
    public var esmInstructions: String?
    public var esmSubmit: String?
    public var esmBack: String?
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

    // MARK: Branches

    /// Questions to ask next, chosen by this question's answer (`esm_flows`). See `ESMFlow`.
    public var esmFlows: [ESMFlow]?

    // MARK: CodingKeys — maps Swift camelCase to JSON snake_case

    public enum CodingKeys: String, CodingKey {
        case esmType                = "esm_type"
        case esmTitle               = "esm_title"
        case esmInstructions        = "esm_instructions"
        case esmSubmit              = "esm_submit"
        case esmBack                = "esm_back"
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
        case esmFlows               = "esm_flows"
    }

    // MARK: Convenience

    public var esmTypeEnum: ESMType? {
        ESMType(rawValue: esmType)
    }

    public init(esmType: Int, esmTitle: String? = nil, esmInstructions: String? = nil,
                esmSubmit: String? = nil, esmBack: String? = nil, esmTrigger: String? = nil) {
        self.esmType = esmType
        self.esmTitle = esmTitle
        self.esmInstructions = esmInstructions
        self.esmSubmit = esmSubmit
        self.esmBack = esmBack
        self.esmTrigger = esmTrigger
    }
}

// MARK: - Decoding

extension ESMItem {

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        esmType                = try c.decode(Int.self, forKey: .esmType)
        esmTitle               = try c.decodeIfPresent(String.self, forKey: .esmTitle)
        esmInstructions        = try c.decodeIfPresent(String.self, forKey: .esmInstructions)
        esmSubmit              = try c.decodeIfPresent(String.self, forKey: .esmSubmit)
        esmBack                = try c.decodeIfPresent(String.self, forKey: .esmBack)
        esmTrigger             = try c.decodeIfPresent(String.self, forKey: .esmTrigger)
        esmExpirationThreshold = try c.decodeIfPresent(Int.self, forKey: .esmExpirationThreshold)
        esmNa                  = try c.decodeIfPresent(Int.self, forKey: .esmNa)
        esmRadios              = try c.decodeIfPresent([String].self, forKey: .esmRadios)
        esmCheckboxes          = try c.decodeIfPresent([String].self, forKey: .esmCheckboxes)
        esmLikertMax           = try c.decodeIfPresent(Int.self, forKey: .esmLikertMax)
        esmLikertMaxLabel      = try c.decodeIfPresent(String.self, forKey: .esmLikertMaxLabel)
        esmLikertMinLabel      = try c.decodeIfPresent(String.self, forKey: .esmLikertMinLabel)
        esmLikertStep          = try c.decodeIfPresent(Int.self, forKey: .esmLikertStep)
        esmQuickAnswers        = try c.decodeIfPresent([String].self, forKey: .esmQuickAnswers)
        esmScaleMax            = try c.decodeIfPresent(Int.self, forKey: .esmScaleMax)
        esmScaleMin            = try c.decodeIfPresent(Int.self, forKey: .esmScaleMin)
        esmScaleStart          = try c.decodeIfPresent(Int.self, forKey: .esmScaleStart)
        esmScaleMaxLabel       = try c.decodeIfPresent(String.self, forKey: .esmScaleMaxLabel)
        esmScaleMinLabel       = try c.decodeIfPresent(String.self, forKey: .esmScaleMinLabel)
        esmScaleStep           = try c.decodeIfPresent(Int.self, forKey: .esmScaleStep)
        esmUrl                 = try c.decodeIfPresent(String.self, forKey: .esmUrl)
        esmCamera              = try c.decodeIfPresent(Int.self, forKey: .esmCamera)
        esmFlows               = try ESMItem.decodeFlows(c)
    }

    /// `esm_flows` is an array of flows. AWAREFramework (v2) stored it as a JSON string holding that
    /// array, so a string is accepted too; an empty string means no flows.
    private static func decodeFlows(_ c: KeyedDecodingContainer<CodingKeys>) throws -> [ESMFlow]? {
        guard c.contains(.esmFlows), try c.decodeNil(forKey: .esmFlows) == false else { return nil }
        if let flows = try? c.decode([ESMFlow].self, forKey: .esmFlows) {
            return flows.isEmpty ? nil : flows
        }
        let text = try c.decode(String.self, forKey: .esmFlows).trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return nil }
        guard let data = text.data(using: .utf8) else {
            throw DecodingError.dataCorruptedError(forKey: .esmFlows, in: c, debugDescription: "Invalid esm_flows")
        }
        let flows = try JSONDecoder().decode([ESMFlow].self, from: data)
        return flows.isEmpty ? nil : flows
    }
}

/// Wrapper matching the JSON structure `{ "esm": { ... } }`.
public struct ESMItemWrapper: Codable, Equatable, Sendable {
    public var esm: ESMItem

    public init(esm: ESMItem) {
        self.esm = esm
    }
}
