import Foundation

/// A branch of an ESM question: when the answer matches `userAnswer`, `nextEsm` is asked next.
///
/// This is the `esm_flows` format of AWARE (AWAREFramework for iOS and the AWARE Android client):
/// ```json
/// "esm_flows": [
///   { "user_answer": "Yes", "next_esm": { "esm": { "esm_type": 1, "esm_title": "Why?" } } },
///   { "user_answer": "*",   "next_esm": { "esm": { ... } } }
/// ]
/// ```
/// A question in `next_esm` can have its own `esm_flows`, so branches can be nested.
///
/// Matching (`matches(_:)`):
/// - `"*"` matches any answer except an empty one and `"NA"` (not applicable).
/// - Otherwise the answer must equal `userAnswer` (surrounding white space is ignored).
/// - For a checkbox question, whose answer is a JSON array of the selected options (for example
///   `["Coffee","Tea"]`), the flow also matches when `userAnswer` is one of the selected options.
public struct ESMFlow: Codable, Equatable, Sendable {

    public var userAnswer: String
    public var nextEsm: ESMItemWrapper

    public enum CodingKeys: String, CodingKey {
        case userAnswer = "user_answer"
        case nextEsm    = "next_esm"
    }

    public init(userAnswer: String, nextEsm: ESMItem) {
        self.userAnswer = userAnswer
        self.nextEsm = ESMItemWrapper(esm: nextEsm)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // The answer key may be written as a number (for example a Likert value: "user_answer": 5)
        if let text = try? c.decode(String.self, forKey: .userAnswer) {
            userAnswer = text
        } else if let number = try? c.decode(Int.self, forKey: .userAnswer) {
            userAnswer = String(number)
        } else {
            userAnswer = String(try c.decode(Double.self, forKey: .userAnswer))
        }
        // `next_esm` is `{ "esm": { ... } }` in AWARE; a bare question object is also accepted
        if let wrapper = try? c.decode(ESMItemWrapper.self, forKey: .nextEsm) {
            nextEsm = wrapper
        } else {
            nextEsm = ESMItemWrapper(esm: try c.decode(ESMItem.self, forKey: .nextEsm))
        }
    }

    /// Whether `answer` (the answer to the question that owns this flow) selects this branch.
    public func matches(_ answer: String) -> Bool {
        let given = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if given.isEmpty || given == ESMFlow.notApplicable { return false }
        if key == "*" || key == given { return true }
        if given.hasPrefix("["),
           let data = given.data(using: .utf8),
           let selected = try? JSONSerialization.jsonObject(with: data) as? [Any] {
            return selected.contains { "\($0)".trimmingCharacters(in: .whitespacesAndNewlines) == key }
        }
        return false
    }

    /// The answer the survey form stores when a question is marked "not applicable".
    public static let notApplicable = "NA"
}

/// A question shown in a survey, with the key its answer is stored under.
public struct ESMSurveyEntry: Equatable, Sendable, Identifiable {
    /// Key of the answer: `esm_trigger`, or a key made from the question's position when it has none.
    public let key: String
    public let item: ESMItem
    /// Key of the question whose answer led to this one (`nil` for a question of the schedule itself).
    public let parentKey: String?
    /// How deep the question is in the branches (0 for a question of the schedule itself).
    public let depth: Int

    public var id: String { key }
}

public enum ESMFlowResolver {

    /// Branches deeper than this are ignored (protects against very deep or generated definitions).
    public static let maxDepth = 16

    /// The questions to show for the given answers, in order.
    ///
    /// Each question is followed by the questions its answer selects (`esm_flows`), recursively, so
    /// the list grows as the questions are answered and shrinks when an answer is changed. The
    /// questions of the schedule keep the keys used before flows existed (`esm_trigger`, or the
    /// question's index), so answers are stored under the same keys as before.
    public static func entries(for items: [ESMItem], answers: [String: String]) -> [ESMSurveyEntry] {
        var out: [ESMSurveyEntry] = []
        var used = Set<String>()
        for (index, item) in items.enumerated() {
            append(item, key: uniqueKey(item.esmTrigger ?? "\(index)", &used), parentKey: nil, depth: 0,
                   answers: answers, used: &used, into: &out)
        }
        return out
    }

    private static func append(_ item: ESMItem, key: String, parentKey: String?, depth: Int,
                               answers: [String: String], used: inout Set<String>,
                               into out: inout [ESMSurveyEntry]) {
        out.append(ESMSurveyEntry(key: key, item: item, parentKey: parentKey, depth: depth))
        guard depth < maxDepth, let flows = item.esmFlows, let answer = answers[key] else { return }
        for (n, flow) in flows.enumerated() where flow.matches(answer) {
            let next = flow.nextEsm.esm
            let nextKey = uniqueKey(next.esmTrigger ?? "\(key)_flow\(n)", &used)
            append(next, key: nextKey, parentKey: key, depth: depth + 1, answers: answers, used: &used, into: &out)
        }
    }

    /// Two questions must not share an answer key; a repeated key gets a numbered suffix.
    private static func uniqueKey(_ key: String, _ used: inout Set<String>) -> String {
        var candidate = key
        var n = 2
        while used.contains(candidate) {
            candidate = "\(key)#\(n)"
            n += 1
        }
        used.insert(candidate)
        return candidate
    }
}

public extension ESMSchedule {

    /// The questions to show for the given answers, including the ones selected by `esm_flows`.
    func surveyEntries(answers: [String: String]) -> [ESMSurveyEntry] {
        ESMFlowResolver.entries(for: esms.map(\.esm), answers: answers)
    }

    /// The answered questions that are part of the survey for these answers, in order. Answers to
    /// questions of a branch that a later change of answer removed are left out.
    func answeredEntries(answers: [String: String]) -> [(entry: ESMSurveyEntry, answer: String)] {
        surveyEntries(answers: answers).compactMap { entry in
            answers[entry.key].map { (entry, $0) }
        }
    }
}
