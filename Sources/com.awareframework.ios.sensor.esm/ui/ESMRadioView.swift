import SwiftUI

public struct ESMRadioView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selected: String?
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(item.esmRadios ?? [], id: \.self) { option in
                radioRow(option)
            }

            if !hideSubmitButton {
                Button(item.esmSubmit ?? "OK") {
                    onSubmit(selected ?? "")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selected == nil)
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }

    private func radioRow(_ option: String) -> some View {
        Button {
            selected = option
            if hideSubmitButton { onSubmit(option) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected == option ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected == option ? Color.accentColor : Color.secondary)
                Text(option)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding()
            .background(selected == option ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
    }
}
