import XCTest
@testable import com_awareframework_ios_sensor_esm

/// Branches of ESM questions (`esm_flows`), in the format of AWAREFramework (v2) and the AWARE dashboard.
final class ESMFlowTests: XCTestCase {

    /// A survey in the AWARE format: "Did you exercise?" leads to a different question for Yes and No,
    /// and the Yes branch has a nested branch.
    private let surveyJSON = """
    [
      {
        "schedule_id": "evening",
        "hours": [20],
        "start_date": "01-01-2024",
        "end_date": "12-31-2050",
        "expiration": 30,
        "randomize": 0,
        "notification_title": "Evening survey",
        "notification_body": "Two minutes",
        "esms": [
          { "esm": {
              "esm_type": 2,
              "esm_title": "Did you exercise today?",
              "esm_radios": ["Yes", "No"],
              "esm_trigger": "exercised",
              "esm_flows": [
                { "user_answer": "Yes",
                  "next_esm": { "esm": {
                    "esm_type": 4, "esm_title": "How intense was it?", "esm_likert_max": 5,
                    "esm_trigger": "intensity",
                    "esm_flows": [
                      { "user_answer": "5",
                        "next_esm": { "esm": { "esm_type": 1, "esm_title": "Any pain?", "esm_trigger": "pain" } } }
                    ] } } },
                { "user_answer": "No",
                  "next_esm": { "esm": { "esm_type": 1, "esm_title": "What stopped you?", "esm_trigger": "barrier" } } }
              ] } },
          { "esm": { "esm_type": 6, "esm_title": "Stress", "esm_scale_min": 0, "esm_scale_max": 10,
                     "esm_trigger": "stress" } }
        ]
      }
    ]
    """

    private func survey() throws -> ESMSchedule {
        try XCTUnwrap(ESMSchedule.parse(from: surveyJSON).first)
    }

    // MARK: - Parsing

    func testParsesNestedFlows() throws {
        let s = try survey()
        let first = s.esms[0].esm
        XCTAssertEqual(first.esmFlows?.count, 2)
        XCTAssertEqual(first.esmFlows?[0].userAnswer, "Yes")
        XCTAssertEqual(first.esmFlows?[0].nextEsm.esm.esmTrigger, "intensity")
        XCTAssertEqual(first.esmFlows?[0].nextEsm.esm.esmFlows?.first?.nextEsm.esm.esmTrigger, "pain")
        XCTAssertNil(s.esms[1].esm.esmFlows)
    }

    /// AWAREFramework (v2) stored esm_flows as a JSON string holding the array
    func testParsesFlowsStoredAsJSONString() throws {
        let json = """
        { "esm_type": 2, "esm_radios": ["Yes", "No"], "esm_trigger": "q",
          "esm_flows": "[{\\"user_answer\\":\\"Yes\\",\\"next_esm\\":{\\"esm\\":{\\"esm_type\\":1,\\"esm_trigger\\":\\"why\\"}}}]" }
        """
        let item = try JSONDecoder().decode(ESMItem.self, from: Data(json.utf8))
        XCTAssertEqual(item.esmFlows?.first?.nextEsm.esm.esmTrigger, "why")
    }

    func testEmptyOrNullFlowsMeanNoFlows() throws {
        for flows in ["\"\"", "[]", "null"] {
            let json = "{ \"esm_type\": 1, \"esm_flows\": \(flows) }"
            let item = try JSONDecoder().decode(ESMItem.self, from: Data(json.utf8))
            XCTAssertNil(item.esmFlows, flows)
        }
    }

    func testAcceptsNumericAnswerKeyAndBareNextESM() throws {
        let json = """
        { "esm_type": 4, "esm_likert_max": 5,
          "esm_flows": [ { "user_answer": 1, "next_esm": { "esm_type": 1, "esm_trigger": "low" } } ] }
        """
        let item = try JSONDecoder().decode(ESMItem.self, from: Data(json.utf8))
        XCTAssertEqual(item.esmFlows?.first?.userAnswer, "1")
        XCTAssertEqual(item.esmFlows?.first?.nextEsm.esm.esmTrigger, "low")
    }

    func testInvalidFlowStringIsAnError() {
        let json = "{ \"esm_type\": 1, \"esm_flows\": \"not json\" }"
        XCTAssertThrowsError(try JSONDecoder().decode(ESMItem.self, from: Data(json.utf8)))
    }

    /// Schedules are saved and restored (for example from a notification), so flows must survive encoding
    func testFlowsSurviveEncoding() throws {
        let s = try survey()
        let data = try JSONEncoder().encode([s])
        let back = try ESMSchedule.parse(from: data)
        XCTAssertEqual(back, [s])
    }

    // MARK: - Matching

    func testMatching() {
        let flow = ESMFlow(userAnswer: "Yes", nextEsm: ESMItem(esmType: 1))
        XCTAssertTrue(flow.matches("Yes"))
        XCTAssertTrue(flow.matches(" Yes "))
        XCTAssertFalse(flow.matches("yes"))
        XCTAssertFalse(flow.matches("No"))
        XCTAssertFalse(flow.matches(""))

        let any = ESMFlow(userAnswer: "*", nextEsm: ESMItem(esmType: 1))
        XCTAssertTrue(any.matches("anything"))
        XCTAssertFalse(any.matches(""))
        XCTAssertFalse(any.matches("NA"), "not applicable selects no branch")
    }

    /// A checkbox answer is a JSON array of the selected options
    func testCheckboxAnswerMatchesSelectedOption() {
        let flow = ESMFlow(userAnswer: "Coffee", nextEsm: ESMItem(esmType: 1))
        XCTAssertTrue(flow.matches(#"["Coffee","Tea"]"#))
        XCTAssertFalse(flow.matches(#"["Tea"]"#))
        XCTAssertTrue(ESMFlow(userAnswer: #"["Tea"]"#, nextEsm: ESMItem(esmType: 1)).matches(#"["Tea"]"#))
    }

    // MARK: - Questions to show

    func testNoAnswersShowsOnlyScheduleQuestions() throws {
        let keys = try survey().surveyEntries(answers: [:]).map(\.key)
        XCTAssertEqual(keys, ["exercised", "stress"])
    }

    func testAnswerInsertsBranchRightAfterItsQuestion() throws {
        let s = try survey()
        XCTAssertEqual(s.surveyEntries(answers: ["exercised": "No"]).map(\.key), ["exercised", "barrier", "stress"])

        let yes = s.surveyEntries(answers: ["exercised": "Yes"])
        XCTAssertEqual(yes.map(\.key), ["exercised", "intensity", "stress"])
        XCTAssertEqual(yes[1].parentKey, "exercised")
        XCTAssertEqual(yes[1].depth, 1)

        let nested = s.surveyEntries(answers: ["exercised": "Yes", "intensity": "5"])
        XCTAssertEqual(nested.map(\.key), ["exercised", "intensity", "pain", "stress"])
        XCTAssertEqual(nested[2].depth, 2)
    }

    /// Changing an answer removes the old branch, and its answers are not kept
    func testChangingAnswerDropsOldBranch() throws {
        let s = try survey()
        let answers = ["exercised": "No", "barrier": "Rain", "intensity": "5", "pain": "Knee", "stress": "3"]
        let saved = s.answeredEntries(answers: answers)
        XCTAssertEqual(saved.map(\.entry.key), ["exercised", "barrier", "stress"])
        XCTAssertEqual(saved.map(\.answer), ["No", "Rain", "3"])
    }

    func testQuestionsWithoutTriggerGetStableKeys() {
        let follow = ESMItem(esmType: 1, esmTitle: "Why?")
        var first = ESMItem(esmType: 2)
        first.esmRadios = ["Yes", "No"]
        first.esmFlows = [ESMFlow(userAnswer: "Yes", nextEsm: follow)]
        let items = [first, ESMItem(esmType: 1)]

        // Without a trigger, the schedule's questions keep their index as key (as before flows existed)
        XCTAssertEqual(ESMFlowResolver.entries(for: items, answers: [:]).map(\.key), ["0", "1"])
        XCTAssertEqual(ESMFlowResolver.entries(for: items, answers: ["0": "Yes"]).map(\.key), ["0", "0_flow0", "1"])
    }

    func testRepeatedTriggerGetsUniqueKey() {
        var first = ESMItem(esmType: 2, esmTrigger: "q")
        first.esmFlows = [ESMFlow(userAnswer: "*", nextEsm: ESMItem(esmType: 1, esmTrigger: "q"))]
        let keys = ESMFlowResolver.entries(for: [first], answers: ["q": "x"]).map(\.key)
        XCTAssertEqual(keys, ["q", "q#2"])
    }

    func testDepthIsLimited() {
        // A chain deeper than maxDepth, where every answer selects the next question
        var item = ESMItem(esmType: 1, esmTrigger: "q\(ESMFlowResolver.maxDepth + 5)")
        for n in stride(from: ESMFlowResolver.maxDepth + 4, through: 0, by: -1) {
            var parent = ESMItem(esmType: 1, esmTrigger: "q\(n)")
            parent.esmFlows = [ESMFlow(userAnswer: "*", nextEsm: item)]
            item = parent
        }
        var answers: [String: String] = [:]
        for n in 0...(ESMFlowResolver.maxDepth + 5) { answers["q\(n)"] = "x" }
        let entries = ESMFlowResolver.entries(for: [item], answers: answers)
        XCTAssertEqual(entries.count, ESMFlowResolver.maxDepth + 1)
    }
}
