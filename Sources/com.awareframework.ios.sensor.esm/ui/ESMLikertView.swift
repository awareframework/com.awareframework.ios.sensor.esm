import SwiftUI

public struct ESMLikertView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selected: Int?
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    private var options: [Int] {
        let maxValue = item.esmLikertMax ?? 5
        let step     = max(1, item.esmLikertStep ?? 1)
        return stride(from: 1, through: maxValue, by: step).map { $0 }
    }

    public var body: some View {
        VStack(spacing: 16) {
            scaleLabels
            scaleButtons
            if !hideSubmitButton {
                submitButton
            }
        }
    }

    private var scaleLabels: some View {
        HStack {
            Text(item.esmLikertMinLabel ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(item.esmLikertMaxLabel ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var scaleButtons: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { value in
                Button {
                    selected = value
                    if hideSubmitButton { onSubmit("\(value)") }
                } label: {
                    Text("\(value)")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selected == value ? Color.accentColor : Color(.systemGray5))
                        .foregroundStyle(selected == value ? .white : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .fontWeight(selected == value ? .semibold : .regular)
                }
            }
        }
        .padding(.horizontal)
    }

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit(selected.map { "\($0)" } ?? "")
        }
        .buttonStyle(.borderedProminent)
        .disabled(selected == nil)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}
