import SwiftUI

public struct ESMNumericView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var text = ""
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 12) {
            TextField("Enter a number", text: $text)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onChange(of: text) { newValue in
                    if hideSubmitButton { onSubmit(newValue) }
                }

            if !hideSubmitButton {
                Button(item.esmSubmit ?? "OK") {
                    onSubmit(text)
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
}
