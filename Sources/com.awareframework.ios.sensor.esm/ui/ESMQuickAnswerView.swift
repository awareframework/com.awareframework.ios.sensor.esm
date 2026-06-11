import SwiftUI

/// Shows a row of large tappable buttons — one tap immediately submits the answer.
public struct ESMQuickAnswerView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 12) {
            ForEach(item.esmQuickAnswers ?? [], id: \.self) { answer in
                Button(answer) {
                    onSubmit(answer)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
}
