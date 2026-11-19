import SwiftUI

public struct ESMCheckboxView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selected: Set<String> = []
    @State private var otherText: String = ""
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton
    @Environment(\.esmInitialAnswer) private var initialAnswer
    @State private var restored = false

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(item.esmCheckboxes ?? [], id: \.self) { option in
                checkboxRow(option)
            }
            .onAppear(perform: restore)

            if !hideSubmitButton {
                Button(item.esmSubmit ?? "OK") {
                    onSubmit(encodeAnswer())
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }

    /// Show the earlier answer (a JSON array of the selected options; "Other: text" for the other option)
    private func restore() {
        guard !restored else { return }
        restored = true
        guard let answer = initialAnswer, let data = answer.data(using: .utf8),
              let values = try? JSONSerialization.jsonObject(with: data) as? [String] else { return }
        let options = item.esmCheckboxes ?? []
        for value in values {
            if options.contains(value) {
                selected.insert(value)
            } else if let other = options.first(where: { isOtherOption($0) && value.hasPrefix("\($0): ") }) {
                selected.insert(other)
                otherText = String(value.dropFirst(other.count + 2))
            }
        }
    }

    private func isOtherOption(_ option: String) -> Bool {
        option.lowercased() == "other" || option == "\u{305D}\u{306E}\u{4ED6}"
    }

    private func checkboxRow(_ option: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                if selected.contains(option) {
                    selected.remove(option)
                    if isOtherOption(option) { otherText = "" }
                } else {
                    selected.insert(option)
                }
                if hideSubmitButton { onSubmit(encodeAnswer()) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selected.contains(option) ? "checkmark.square.fill" : "square")
                        .foregroundStyle(selected.contains(option) ? Color.accentColor : Color.secondary)
                    Text(option)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding()
                .background(selected.contains(option) ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            if isOtherOption(option) && selected.contains(option) {
                TextField("Enter details...", text: $otherText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 4)
                    .onChange(of: otherText) { _ in
                        if hideSubmitButton { onSubmit(encodeAnswer()) }
                    }
            }
        }
        .padding(.horizontal)
    }

    private func encodeAnswer() -> String {
        var items = Array(selected)
        if !otherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items = items.map { isOtherOption($0) ? "\($0): \(otherText)" : $0 }
        }
        let sorted = items.sorted()
        return (try? String(data: JSONSerialization.data(withJSONObject: sorted), encoding: .utf8)) ?? ""
    }
}
