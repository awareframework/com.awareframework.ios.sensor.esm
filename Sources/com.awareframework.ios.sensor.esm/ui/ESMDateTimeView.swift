import SwiftUI

public struct ESMDateTimeView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selectedDate = Date()
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    private var displayedComponents: DatePickerComponents {
        switch ESMType(rawValue: item.esmType) {
        case .datePicker: return .date
        case .clock:      return .hourAndMinute
        default:          return [.date, .hourAndMinute]
        }
    }

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public var body: some View {
        VStack(spacing: 16) {
            DatePicker("", selection: $selectedDate, displayedComponents: displayedComponents)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)
                .onChange(of: selectedDate) { newDate in
                    if hideSubmitButton {
                        onSubmit(ESMDateTimeView.iso8601.string(from: newDate))
                    }
                }

            if !hideSubmitButton {
                Button(item.esmSubmit ?? "OK") {
                    onSubmit(ESMDateTimeView.iso8601.string(from: selectedDate))
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
}
