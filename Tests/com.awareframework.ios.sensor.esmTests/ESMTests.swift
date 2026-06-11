import XCTest
@testable import com_awareframework_ios_sensor_esm

final class ESMTests: XCTestCase {

    // MARK: - JSON Parsing

    func testParseSingleSchedule() throws {
        let json = """
        [
          {
            "schedule_id": "daily_mood",
            "hours": [9, 17],
            "start_date": "01-01-2024",
            "end_date": "12-31-2050",
            "expiration": 30,
            "randomize": 10,
            "notification_title": "Daily Survey",
            "notification_body": "Please answer a few questions",
            "esms": [
              {
                "esm": {
                  "esm_type": 4,
                  "esm_title": "How are you feeling?",
                  "esm_instructions": "Choose a number from 1 to 5",
                  "esm_likert_max": 5,
                  "esm_likert_max_label": "Great",
                  "esm_likert_min_label": "Poor",
                  "esm_likert_step": 1,
                  "esm_submit": "Submit",
                  "esm_trigger": "daily_mood_0_likert"
                }
              }
            ]
          }
        ]
        """

        let schedules = try ESMSchedule.parse(from: json)
        XCTAssertEqual(schedules.count, 1)

        let s = schedules[0]
        XCTAssertEqual(s.scheduleId, "daily_mood")
        XCTAssertEqual(s.hours, [9, 17])
        XCTAssertEqual(s.expiration, 30)
        XCTAssertEqual(s.randomize, 10)
        XCTAssertEqual(s.notificationTitle, "Daily Survey")
        XCTAssertEqual(s.esms.count, 1)

        let item = s.esms[0].esm
        XCTAssertEqual(item.esmType, 4)
        XCTAssertEqual(item.esmTypeEnum, .likert)
        XCTAssertEqual(item.esmTitle, "How are you feeling?")
        XCTAssertEqual(item.esmLikertMax, 5)
        XCTAssertEqual(item.esmLikertMaxLabel, "Great")
        XCTAssertEqual(item.esmTrigger, "daily_mood_0_likert")
    }

    func testParseAllQuestionTypes() throws {
        let json = """
        [
          {
            "schedule_id": "all_types",
            "hours": [12],
            "start_date": "01-01-2024",
            "end_date": "12-31-2050",
            "expiration": 0,
            "randomize": 0,
            "notification_title": "Test",
            "notification_body": "Test",
            "esms": [
              { "esm": { "esm_type": 1, "esm_title": "Free Text",    "esm_submit": "OK" } },
              { "esm": { "esm_type": 2, "esm_title": "Radio",        "esm_radios": ["A","B","C"], "esm_submit": "OK" } },
              { "esm": { "esm_type": 3, "esm_title": "Checkbox",     "esm_checkboxes": ["X","Y"], "esm_submit": "OK" } },
              { "esm": { "esm_type": 4, "esm_title": "Likert",       "esm_likert_max": 7, "esm_submit": "OK" } },
              { "esm": { "esm_type": 5, "esm_title": "Quick Answer", "esm_quick_answers": ["Yes","No"], "esm_submit": "OK" } },
              { "esm": { "esm_type": 6, "esm_title": "Scale",        "esm_scale_min": 0, "esm_scale_max": 100, "esm_submit": "OK" } },
              { "esm": { "esm_type": 7, "esm_title": "DateTime",     "esm_submit": "OK" } },
              { "esm": { "esm_type": 8, "esm_title": "PAM",          "esm_submit": "OK" } },
              { "esm": { "esm_type": 9, "esm_title": "Numeric",      "esm_submit": "OK" } },
              { "esm": { "esm_type": 10,"esm_title": "Web",          "esm_url": "https://example.com", "esm_submit": "OK" } }
            ]
          }
        ]
        """

        let schedules = try ESMSchedule.parse(from: json)
        let esms = schedules[0].esms
        XCTAssertEqual(esms.count, 10)

        let types = esms.map { $0.esm.esmTypeEnum }
        XCTAssertEqual(types[0], .freeText)
        XCTAssertEqual(types[1], .radio)
        XCTAssertEqual(types[2], .checkbox)
        XCTAssertEqual(types[3], .likert)
        XCTAssertEqual(types[4], .quickAnswer)
        XCTAssertEqual(types[5], .scale)
        XCTAssertEqual(types[6], .dateTime)
        XCTAssertEqual(types[7], .pam)
        XCTAssertEqual(types[8], .numeric)
        XCTAssertEqual(types[9], .web)

        XCTAssertEqual(esms[1].esm.esmRadios, ["A", "B", "C"])
        XCTAssertEqual(esms[2].esm.esmCheckboxes, ["X", "Y"])
        XCTAssertEqual(esms[3].esm.esmLikertMax, 7)
        XCTAssertEqual(esms[4].esm.esmQuickAnswers, ["Yes", "No"])
        XCTAssertEqual(esms[5].esm.esmScaleMax, 100)
        XCTAssertEqual(esms[9].esm.esmUrl, "https://example.com")
    }

    func testParseAwareESMHelperAllTypesSample() throws {
        let sampleURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Examples/esm_all_types_sample.json")

        let schedules = try ESMSchedule.parse(from: sampleURL)
        XCTAssertEqual(schedules.count, 1)

        let schedule = schedules[0]
        XCTAssertEqual(schedule.scheduleId, "esm_all_types")
        XCTAssertEqual(schedule.hours, [9, 13, 18])
        XCTAssertEqual(schedule.expiration, 30)
        XCTAssertEqual(schedule.randomize, 15)
        XCTAssertEqual(schedule.interface, 0)

        let types = schedule.esms.map(\.esm.esmTypeEnum)
        XCTAssertEqual(types, ESMType.allCases.map(Optional.some))

        XCTAssertEqual(schedule.esms[1].esm.esmRadios, ["Home", "Work", "School", "In transit", "Other"])
        XCTAssertEqual(schedule.esms[2].esm.esmCheckboxes, ["Walking", "Talking", "Eating", "Using phone", "Resting"])
        XCTAssertEqual(schedule.esms[3].esm.esmLikertMaxLabel, "Very good")
        XCTAssertEqual(schedule.esms[4].esm.esmQuickAnswers, ["Yes", "No", "Maybe"])
        XCTAssertEqual(schedule.esms[5].esm.esmScaleStart, 5)
        XCTAssertEqual(schedule.esms[9].esm.esmUrl, "https://example.com/esm")
        XCTAssertEqual(schedule.esms[12].esm.esmCamera, 0)
        XCTAssertEqual(schedule.esms[14].esm.esmCamera, 0)
    }

    func testMultipleSchedules() throws {
        let json = """
        [
          {
            "schedule_id": "morning",
            "hours": [8],
            "start_date": "01-01-2024",
            "end_date": "12-31-2050",
            "expiration": 60,
            "randomize": 0,
            "notification_title": "Morning",
            "notification_body": "Good morning!",
            "esms": [
              { "esm": { "esm_type": 5, "esm_quick_answers": ["Good","Bad"], "esm_trigger": "morning_mood" } }
            ]
          },
          {
            "schedule_id": "evening",
            "hours": [20],
            "start_date": "01-01-2024",
            "end_date": "12-31-2050",
            "expiration": 60,
            "randomize": 5,
            "notification_title": "Evening",
            "notification_body": "How was your day?",
            "esms": [
              { "esm": { "esm_type": 6, "esm_scale_min": 1, "esm_scale_max": 10, "esm_trigger": "day_rating" } }
            ]
          }
        ]
        """

        let schedules = try ESMSchedule.parse(from: json)
        XCTAssertEqual(schedules.count, 2)
        XCTAssertEqual(schedules[0].scheduleId, "morning")
        XCTAssertEqual(schedules[1].scheduleId, "evening")
        XCTAssertEqual(schedules[1].randomize, 5)
    }

    // MARK: - Schedule date helpers

    func testIsActiveReturnsTrueForCurrentDate() {
        let schedule = ESMSchedule(
            scheduleId: "test",
            hours: [12],
            startDate: "01-01-2000",
            endDate: "12-31-2099",
            notificationTitle: "T",
            notificationBody: "B",
            esms: []
        )
        XCTAssertTrue(schedule.isActive)
    }

    func testIsActiveReturnsFalseForExpiredSchedule() {
        let schedule = ESMSchedule(
            scheduleId: "test",
            hours: [12],
            startDate: "01-01-2000",
            endDate: "01-01-2001",
            notificationTitle: "T",
            notificationBody: "B",
            esms: []
        )
        XCTAssertFalse(schedule.isActive)
    }

    // MARK: - ESMData

    func testESMDataRoundTrip() {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let data = ESMData(
            timestamp: now,
            scheduleId: "s1",
            esmTrigger: "s1_0_likert",
            esmType: 4,
            esmTitle: "Mood",
            esmAnswer: "3",
            esmStatus: ESMStatus.answered.rawValue
        )

        let dict = data.toDictionary()
        XCTAssertEqual(dict["scheduleId"] as? String, "s1")
        XCTAssertEqual(dict["esmTrigger"] as? String, "s1_0_likert")
        XCTAssertEqual(dict["esmType"] as? Int, 4)
        XCTAssertEqual(dict["esmAnswer"] as? String, "3")
        XCTAssertEqual(dict["esmStatus"] as? Int, ESMStatus.answered.rawValue)

        let restored = ESMData(dict)
        XCTAssertEqual(restored.scheduleId, data.scheduleId)
        XCTAssertEqual(restored.esmAnswer, data.esmAnswer)
    }

    // MARK: - ESMType

    func testAllESMTypesHaveDisplayNames() {
        for type_ in ESMType.allCases {
            XCTAssertFalse(type_.displayName.isEmpty, "\(type_) has no display name")
        }
    }
}
