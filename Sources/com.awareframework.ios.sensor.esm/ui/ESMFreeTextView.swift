import SwiftUI

public struct ESMFreeTextView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var text = ""
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $text)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .onChange(of: text) { newValue in
                    if hideSubmitButton { onSubmit(newValue) }
                }

            if !hideSubmitButton {
                submitButton
            }
        }
    }

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit(text)
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}
