# AWARE: ESM

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

**Aware ESM** (`com.awareframework.ios.sensor.esm`) is a plugin for the AWARE Framework. It loads Experience Sampling Method (ESM) survey schedules from JSON, schedules local notifications, presents survey items through the provided SwiftUI views, and stores answer, dismissal, and expiration events.

## Requirements
iOS 16 or later.

## Installation

You can integrate this framework into your project via Swift Package Manager (SwiftPM).

### SwiftPM
1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `git@github.com:awareframework/com.awareframework.ios.sensor.esm.git`

3. Import the package into your target.

4. Import the library into your source code.
```swift
import com_awareframework_ios_sensor_esm
```

## Public functions

### ESMSensor

* `init(_ config: ESMSensor.Config)` : Initializes the ESM sensor with the optional configuration.
* `start()` : Requests local notification permission and posts the ESM start notification.
* `stop()` : Posts the ESM stop notification.
* `sync(force:)` : Syncs stored ESM response records.
* `loadSchedules(from jsonString: String)` : Loads schedule JSON from a string and activates local notifications.
* `loadSchedules(from data: Data)` : Loads schedule JSON from raw data.
* `loadSchedules(from url: URL)` : Loads schedule JSON from a local file URL.
* `submitAnswer(item:scheduleId:answer:notificationTime:)` : Saves an answered ESM item.
* `dismissESM(item:scheduleId:notificationTime:)` : Saves a dismissed ESM item.
* `expireESM(item:scheduleId:notificationTime:)` : Saves an expired ESM item.

### ESMScheduleManager

* `loadSchedules(from:)` : Parses and activates ESM schedules.
* `activateSchedules(_:)` : Replaces the current schedule set and reschedules notifications.
* `activeSchedules()` : Returns schedules that are currently within their start and end date window.
* `loadedSchedules()` : Returns all persisted schedules.
* `clearSchedules()` : Removes persisted schedules and pending ESM notifications.
* `requestPermission(completion:)` : Requests local notification permission.
* `schedule(from:)` : Resolves a notification payload to an active, non-expired schedule.

### ESMSensor.Config

Class to hold the configuration of the sensor.

#### Fields

* `sensorObserver: ESMSensorObserver?` : Callback for schedule and response events.
* `enabled: Bool` : Sensor is enabled or not. (default = `false`)
* `debug: Bool` : Enables or disables logging to the Xcode console. (default = `false`)
* `label: String` : Label for the data. (default = "")
* `deviceId: String` : Device ID associated with events and the sensor.
* `dbType: Engine.DatabaseType` : Database engine used for saving data.
* `dbPath: String` : Path of the database.
* `dbHost: String` : Host for syncing the database.

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

## Broadcasts

### Fired Broadcasts

* `ESMSensor.ACTION_AWARE_ESM_START` fired when the ESM sensor starts.
* `ESMSensor.ACTION_AWARE_ESM_STOP` fired when the ESM sensor stops.
* `ESMSensor.ACTION_AWARE_ESM_ANSWERED` fired when an ESM response is saved.
* `ESMSensor.ACTION_AWARE_ESM_DISMISSED` fired when an ESM item is dismissed.
* `ESMSensor.ACTION_AWARE_ESM_EXPIRED` fired when an ESM item expires.
* `ESMSensor.ACTION_AWARE_ESM_SYNC` fired when ESM data sync starts.
* `ESMSensor.ACTION_AWARE_ESM_SYNC_COMPLETION` fired when ESM data sync completes.

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

## Example usage

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

### Presenting an ESM form

The package includes SwiftUI views for supported ESM item types and `ESMFormView` for rendering a full schedule.

```swift
ESMFormView(
    schedule: schedule,
    notificationTime: notificationTime,
    onCompleted: { answers in
        for (trigger, answer) in answers {
            let item = schedule.esms.first { $0.esm.esmTrigger == trigger }?.esm
            if let item {
                sensor.submitAnswer(
                    item: item,
                    scheduleId: schedule.scheduleId,
                    answer: answer,
                    notificationTime: notificationTime
                )
            }
        }
    },
    onDismissed: {
        for wrapper in schedule.esms {
            sensor.dismissESM(
                item: wrapper.esm,
                scheduleId: schedule.scheduleId,
                notificationTime: notificationTime
            )
        }
    }
)
```

## PAM (Photographic Affect Meter)

The PAM question type (type 8) presents a 4×4 grid of photographs arranged on the circumplex model of affect (valence × arousal). The user selects the image that best matches their current emotional state.

**Images** are sourced from the [smalldatalab/android-pam](https://github.com/smalldatalab/android-pam) repository and are fetched at runtime from:

```
https://raw.githubusercontent.com/smalldatalab/android-pam/master/app/src/main/assets/pam_images/{id}_{name}/{id}_1.jpg
```

The 16 affect categories are arranged as follows:

|  | Unpleasant ← | → Pleasant |  |
|---|---|---|---|
| **High Arousal** ↑ | Afraid | Tense | Excited | Delighted |
|  | Frustrated | Angry | Happy | Glad |
|  | Miserable | Sad | Calm | Satisfied |
| **Low Arousal** ↓ | Gloomy | Tired | Sleepy | Serene |

**Reference:**

> Pollak, J. P., Adams, P., & Gay, G. (2011). PAM: a photographic affect meter for frequent, in situ measurement of affect. In *Proceedings of the SIGCHI Conference on Human Factors in Computing Systems* (CHI '11), pp. 725–734. ACM.
> https://dl.acm.org/doi/10.1145/1978942.1979047

## Author

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## License

Copyright (c) 2025 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
