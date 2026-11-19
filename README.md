# AWARE: ESM

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**Aware ESM** (`com.awareframework.ios.sensor.esm`) is a plugin for the AWARE Framework. It loads Experience Sampling Method (ESM) survey schedules from JSON, schedules local notifications, presents survey items through the provided SwiftUI views, and stores answer, dismissal, and expiration events.

## Requirements
iOS 16 or later.

## Installation
Add the package with Swift Package Manager:

- Package URL: `https://github.com/awareframework/com.awareframework.ios.sensor.esm.git`
- Product: `com.awareframework.ios.sensor.esm`
- Module: `import com_awareframework_ios_sensor_esm`

See the [core package README](https://github.com/awareframework/com.awareframework.ios.core#installation) for the Xcode, `Package.swift` and command-line installation steps.

**Info.plist:** local notifications need no usage description. Only the media question types do: `NSCameraUsageDescription` for Picture (14) and Video (16), and `NSMicrophoneUsageDescription` for Audio (15) and Video.

## Public Functions

### ESMSensor

+ `init(_ config: ESMSensor.Config)`: Initializes the ESM sensor with the optional configuration.
+ `start()`: Requests local notification permission and posts the ESM start notification.
+ `stop()`: Posts the ESM stop notification.
+ `sync(force:)`: Syncs stored ESM response records.
+ `loadSchedules(from jsonString: String)`: Loads schedule JSON from a string and activates local notifications.
+ `loadSchedules(from data: Data)`: Loads schedule JSON from raw data.
+ `loadSchedules(from url: URL)`: Loads schedule JSON from a local file URL.
+ `submitAnswer(item:scheduleId:answer:notificationTime:)`: Saves an answered ESM item.
+ `submitAnswers(schedule:answers:notificationTime:)`: Saves the answers that `ESMFormView` returns, including the questions selected by branches (`esm_flows`). Returns the number saved.
+ `dismissESM(item:scheduleId:notificationTime:)`: Saves a dismissed ESM item.
+ `expireESM(item:scheduleId:notificationTime:)`: Saves an expired ESM item.

### ESMScheduleManager

+ `loadSchedules(from:)`: Parses and activates ESM schedules.
+ `activateSchedules(_:)`: Replaces the current schedule set and reschedules notifications.
+ `activeSchedules()`: Returns schedules that are currently within their start and end date window.
+ `loadedSchedules()`: Returns all persisted schedules.
+ `clearSchedules()`: Removes persisted schedules and pending ESM notifications.
+ `requestPermission(completion:)`: Requests local notification permission.
+ `schedule(from:)`: Resolves a notification payload to an active, non-expired schedule.

### ESMSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: ESMSensorObserver?`: Callback for schedule and response events.
+ `enabled: Bool`: Sensor is enabled or not. (default = `false`)
+ `debug: Bool`: Enables or disables logging to the Xcode console. (default = `false`)
+ `label: String`: Label for the data. (default = `""`)
+ `deviceId: String`: Device ID associated with events and the sensor.
+ `dbType: DatabaseType`: Database engine used for saving data.
+ `dbPath: String`: Path of the database.
+ `dbHost: String?`: Host for syncing the database.

## Supported ESM types

| Type | Name | JSON fields |
| ---- | ---- | ----------- |
| 1 | Free Text | common fields |
| 2 | Radio | `esm_radios` |
| 3 | Checkbox | `esm_checkboxes` |
| 4 | Likert Scale | `esm_likert_max`, `esm_likert_min_label`, `esm_likert_max_label`, `esm_likert_step` |
| 5 | Quick Answer | `esm_quick_answers` |
| 6 | Scale | `esm_scale_min`, `esm_scale_max`, `esm_scale_start`, `esm_scale_min_label`, `esm_scale_max_label`, `esm_scale_step` |
| 7 | DateTime | common fields |
| 8 | PAM (Photographic Affect Meter) | common fields |
| 9 | Numeric | common fields |
| 10 | Web | `esm_url` |
| 11 | Date Picker | common fields |
| 13 | Clock | common fields |
| 14 | Picture | `esm_camera` |
| 15 | Audio | common fields |
| 16 | Video | `esm_camera` |

## Schedule JSON

The schedule JSON is an array of schedule objects. Dates use `MM-dd-yyyy` format.

```json
[
  {
    "schedule_id": "daily_mood",
    "hours": [9, 17],
    "start_date": "01-01-2026",
    "end_date": "12-31-2050",
    "expiration": 30,
    "randomize": 10,
    "notification_title": "Daily Survey",
    "notification_body": "Please answer a few questions",
    "interface": 0,
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
          "esm_trigger": "daily_mood_0_likert",
          "esm_expiration_threshold": 60,
          "esm_na": 0
        }
      }
    ]
  }
]
```

A complete all-types sample is available at `Examples/esm_all_types_sample.json`.

### Schedule fields

| Field | Type | Required | Description |
|---|---|---|---|
| `schedule_id` | String | yes | Unique ID. Stored with each answer (`scheduleId`) and in the notification. |
| `hours` | [Int] | yes | Hours of the day (0–23) at which to notify, at minute 0. `[9, 13, 19]` notifies three times a day. |
| `start_date`, `end_date` | String | yes | First and last day of the schedule, `MM-dd-yyyy`. The schedule notifies on every day in this range (see `weekdays`). |
| `expiration` | Int | yes | Minutes after the notification during which the survey can be answered. `0` means no limit. |
| `randomize` | Int | yes | Random offset of ± this many minutes added to each notification time. `0` means exact times. |
| `weekdays` | [String] | no | Days to notify on, e.g. `["Monday", "Friday"]`. Omit for every day. |
| `notification_title`, `notification_body` | String | yes | Notification text. |
| `interface` | Int | no | `0` or omitted: one question per page. `1`: all questions on one scrolling page. |
| `esms` | Array | yes | Questions, each wrapped as `{"esm": {...}}`. |

### Common question fields

| Field | Description |
|---|---|
| `esm_type` | Question type (see [Supported ESM types](#supported-esm-types)). |
| `esm_trigger` | Question ID. `ESMFormView` returns answers keyed by this value, so make it unique within a schedule. |
| `esm_title`, `esm_instructions` | Question text. |
| `esm_submit` | Label of the submit button. (default = `"Submit"`) |
| `esm_na` | Non-zero shows a "Not applicable" option. |
| `esm_flows` | Branches: questions to ask next, chosen by this question's answer. See [Branches](#branches-esm_flows). |

Likert answers are the selected value as a string, from `"1"` to `esm_likert_max` in steps of `esm_likert_step`.

## Branches (`esm_flows`)

A question can lead to other questions depending on its answer. The format is the one used by
AWAREFramework (v2) and the AWARE dashboard:

```json
{ "esm": {
    "esm_type": 2,
    "esm_title": "Did you exercise today?",
    "esm_radios": ["Yes", "No"],
    "esm_trigger": "exercised",
    "esm_flows": [
      { "user_answer": "Yes",
        "next_esm": { "esm": { "esm_type": 4, "esm_title": "How intense was it?", "esm_likert_max": 5,
                               "esm_trigger": "intensity" } } },
      { "user_answer": "No",
        "next_esm": { "esm": { "esm_type": 1, "esm_title": "What stopped you?", "esm_trigger": "barrier" } } }
    ] } }
```

+ A flow is chosen when the answer equals `user_answer` (white space around it is ignored). `"*"` matches any
  answer except an empty one and `"NA"` (not applicable). For a checkbox question, a flow is also chosen when
  `user_answer` is one of the selected options. Several flows can match; their questions are asked in order.
+ A question in `next_esm` can have its own `esm_flows`, so branches can be nested (up to 16 levels).
+ `esm_flows` can also be a JSON string holding the array, as AWAREFramework stored it.
+ `ESMFormView` inserts the chosen questions right after the answered question: in one-by-one mode they come
  next, and in single-line mode they appear below it (indented). Changing an answer removes the questions of the
  branch it no longer chooses, and their answers are not returned.
+ Give each question in a branch a unique `esm_trigger`. A question without one is keyed
  `<parent key>_flow<n>`.
+ Save the answers with `submitAnswers(schedule:answers:notificationTime:)`, which also saves the answers to
  questions in branches (looping over `schedule.esms` alone would miss them). `ESMSchedule.surveyEntries(answers:)`
  returns the questions shown for given answers, if you build your own form.

## Broadcasts

### Fired Broadcasts

+ `ESMSensor.ACTION_AWARE_ESM_START`: fired when the ESM sensor starts.
+ `ESMSensor.ACTION_AWARE_ESM_STOP`: fired when the ESM sensor stops.
+ `ESMSensor.ACTION_AWARE_ESM_ANSWERED`: fired when an ESM response is saved.
+ `ESMSensor.ACTION_AWARE_ESM_DISMISSED`: fired when an ESM item is dismissed.
+ `ESMSensor.ACTION_AWARE_ESM_EXPIRED`: fired when an ESM item expires.
+ `ESMSensor.ACTION_AWARE_ESM_SYNC`: fired when ESM data sync starts.
+ `ESMSensor.ACTION_AWARE_ESM_SYNC_COMPLETION`: fired when ESM data sync completes.

## Data Representations

### ESM Data

| Field | Type | Description |
| ----- | ---- | ----------- |
| id | Int64 | Local database primary key |
| deviceId | String | AWARE device UUID |
| timestamp | Int64 | Unix time in milliseconds when the record was created |
| timezone | Int | Raw timezone offset of the device |
| os | String | Operating system of the device |
| jsonVersion | Int | JSON schema version |
| label | String | Customizable data label |
| scheduleId | String | Parent schedule ID |
| esmTrigger | String | ESM trigger identifier |
| esmType | Int | Numeric ESM type |
| esmTitle | String | Question title |
| esmInstructions | String | Question instructions |
| esmAnswer | String | Answer value. Multi-value answers can be JSON encoded |
| esmAnswerTime | Int64 | Unix time in milliseconds when the answer was submitted |
| esmStatus | Int | `0=new`, `1=answered`, `2=dismissed`, `3=expired` |
| esmNotificationTime | Int64 | Unix time in milliseconds when the notification fired |

## Example Usage

```swift
let sensor = ESMSensor(ESMSensor.Config().apply { config in
    config.debug = true
    config.dbType = .sqlite
    config.dbPath = "aware_esm"
    config.dbTableName = ESMData.databaseTableName
    config.sensorObserver = Observer()
})

sensor.start()

let url = Bundle.main.url(forResource: "esm_schedule", withExtension: "json")!
try sensor.loadSchedules(from: url)
```

```swift
class Observer: ESMSensorObserver {
    func onScheduleLoaded(schedules: [ESMSchedule]) {
        print("Loaded schedules:", schedules.count)
    }

    func onESMAnswered(data: ESMData) {
        print("Answered:", data.esmTrigger, data.esmAnswer)
    }

    func onESMDismissed(data: ESMData) {
        print("Dismissed:", data.esmTrigger)
    }

    func onESMExpired(data: ESMData) {
        print("Expired:", data.esmTrigger)
    }
}
```

## How notifications are scheduled

- `loadSchedules(...)` stores the schedules (in `UserDefaults`), cancels pending ESM notifications, and schedules **one-shot** local notifications for every day and hour from today until `end_date`.
- iOS keeps at most 64 pending notifications, so the package schedules at most **56** ahead. With three notifications a day this covers about 18 days. **Call `loadSchedules` again at every app launch** to schedule the following days.
- Each notification carries `scheduleId` and `notificationTime` (Unix time in milliseconds) in `userInfo`, and offers *Answer* and *Dismiss* actions.
- `ESMScheduleManager.shared.schedule(from: userInfo)` returns the schedule for a notification, or `nil` once `expiration` minutes have passed or the schedule has ended.
- Expiration is not recorded automatically. Call `expireESM(...)` if you want expired surveys in the data.

## Showing the survey

Set a `UNUserNotificationCenter` delegate before the app finishes launching, so that a tap that launches the app is delivered. Then present `ESMFormView` for the tapped notification:

```swift
import SwiftUI
import UserNotifications
import com_awareframework_ios_sensor_esm

struct PendingESM: Identifiable {
    let schedule: ESMSchedule
    let notificationTime: Int64
    var id: String { "\(schedule.scheduleId)-\(notificationTime)" }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var pending: PendingESM?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show the notification while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // The participant tapped the notification or its Answer action.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if response.actionIdentifier != ESMScheduleManager.actionDismiss,
           let schedule = ESMScheduleManager.shared.schedule(from: userInfo) {
            let time = userInfo["notificationTime"] as? Int64 ?? 0
            DispatchQueue.main.async { self.pending = PendingESM(schedule: schedule, notificationTime: time) }
        }
        completionHandler()
    }
}

@main
struct StudyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let esm = ESMSensor(ESMSensor.Config())

    init() {
        esm.start()   // requests notification permission
        if let url = Bundle.main.url(forResource: "esm_schedule", withExtension: "json") {
            try? esm.loadSchedules(from: url)   // at every launch, to schedule the next days
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(item: $appDelegate.pending) { p in
                    ESMFormView(
                        schedule: p.schedule,
                        notificationTime: p.notificationTime,
                        onCompleted: { answers in            // [esm_trigger: answer]
                            // Saves every answered question, including those selected by esm_flows
                            esm.submitAnswers(schedule: p.schedule, answers: answers,
                                              notificationTime: p.notificationTime)
                            appDelegate.pending = nil
                        },
                        onDismissed: {
                            for wrapper in p.schedule.esms {
                                esm.dismissESM(item: wrapper.esm, scheduleId: p.schedule.scheduleId,
                                               notificationTime: p.notificationTime)
                            }
                            appDelegate.pending = nil
                        }
                    )
                }
        }
    }
}
```

To also offer the survey when the participant opens the app without tapping the notification, look for a delivered notification that has not expired yet:

```swift
UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
    let latest = notifications
        .filter { $0.request.content.categoryIdentifier == ESMScheduleManager.notificationCategoryIdentifier }
        .sorted { $0.date > $1.date }
        .first
    guard let userInfo = latest?.request.content.userInfo,
          let schedule = ESMScheduleManager.shared.schedule(from: userInfo) else { return }
    let time = userInfo["notificationTime"] as? Int64 ?? 0
    DispatchQueue.main.async { appDelegate.pending = PendingESM(schedule: schedule, notificationTime: time) }
}
```

## Storage and sync

- Answers, dismissals and expirations are saved as `ESMData` rows in the `ios_esm` table of the `aware_esm` database.
- Unlike most sensor packages, `ESMSensor` uploads with the `serverType`, `studyNumber` and `studyKey` of its own `ESMSensor.Config`, so set them there together with `dbHost`.
- To include ESM in periodic sync, call `esm.enable()` (or register it with `SensorManager` and call `enableAllSensors()`), then start a `DbSyncManager`. See the [core package README](https://github.com/awareframework/com.awareframework.ios.core#dbsyncmanager-reference) for sync settings and guarantees.

## PAM (Photographic Affect Meter)

The PAM question type (type 8) presents a 4×4 grid of photographs arranged on the circumplex model of affect (valence × arousal). The user selects the image that best matches their current emotional state.

**Images** are sourced from the [smalldatalab/android-pam](https://github.com/smalldatalab/android-pam) repository and are fetched at runtime from:

```
https://raw.githubusercontent.com/smalldatalab/android-pam/master/app/src/main/assets/pam_images/{id}_{name}/{id}_1.jpg
```

The 16 affect categories are arranged as follows:

|  | **Unpleasant ←** |  | **→ Pleasant** |
|---|---|---|---|
| **High Arousal** ↑ | Afraid | Tense | Excited | Delighted |
|  | Frustrated | Angry | Happy | Glad |
|  | Miserable | Sad | Calm | Satisfied |
| **Low Arousal** ↓ | Gloomy | Tired | Sleepy | Serene |

**Reference:**

> Pollak, J. P., Adams, P., & Gay, G. (2011). PAM: a photographic affect meter for frequent, in situ measurement of affect. In *Proceedings of the SIGCHI Conference on Human Factors in Computing Systems* (CHI '11), pp. 725–734. ACM.
> https://dl.acm.org/doi/10.1145/1978942.1979047

## Related Links

- [UserNotifications | Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications)
- [SwiftUI | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui)
- [PhotosUI | Apple Developer Documentation](https://developer.apple.com/documentation/photosui)
- [AVFoundation | Apple Developer Documentation](https://developer.apple.com/documentation/avfoundation)
- [AVKit | Apple Developer Documentation](https://developer.apple.com/documentation/avkit)
- [WebKit | Apple Developer Documentation](https://developer.apple.com/documentation/webkit)

## Author

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## License

Copyright (c) 2025 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
