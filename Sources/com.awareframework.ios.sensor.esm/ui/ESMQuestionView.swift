import SwiftUI

// MARK: - Environment key

private struct ESMHideSubmitButtonKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// When `true`, per-question submit buttons are hidden and the parent
    /// provides a single global Submit button (single-line mode).
    var esmHideSubmitButton: Bool {
        get { self[ESMHideSubmitButtonKey.self] }
        set { self[ESMHideSubmitButtonKey.self] = newValue }
    }
}

// MARK: -

/// Dispatches to the correct type-specific question view based on `item.esmType`.
public struct ESMQuestionView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void
    /// When `true` the outer ScrollView is omitted so the view can be safely
    /// embedded inside an existing scroll container (single-line mode).
    let isEmbedded: Bool

    public init(
        item: ESMItem,
        onSubmit: @escaping (String) -> Void,
        isEmbedded: Bool = false
    ) {
        self.item = item
        self.onSubmit = onSubmit
        self.isEmbedded = isEmbedded
    }

    public var body: some View {
        if isEmbedded {
            content
        } else {
            ScrollView { content }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            inputView
                .padding(.bottom, 16)
        }
        .padding(.top, 16)
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = item.esmTitle, !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
            }
            if let instructions = item.esmInstructions, !instructions.isEmpty {
                Text(instructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: Input dispatch

    @ViewBuilder
    private var inputView: some View {
        switch ESMType(rawValue: item.esmType) {
        case .freeText:
            ESMFreeTextView(item: item, onSubmit: onSubmit)
        case .radio:
            ESMRadioView(item: item, onSubmit: onSubmit)
        case .checkbox:
            ESMCheckboxView(item: item, onSubmit: onSubmit)
        case .likert:
            ESMLikertView(item: item, onSubmit: onSubmit)
        case .quickAnswer:
            ESMQuickAnswerView(item: item, onSubmit: onSubmit)
        case .scale:
            ESMScaleView(item: item, onSubmit: onSubmit)
        case .dateTime, .datePicker, .clock:
            ESMDateTimeView(item: item, onSubmit: onSubmit)
        case .pam:
            ESMPAMView(item: item, onSubmit: onSubmit)
        case .numeric:
            ESMNumericView(item: item, onSubmit: onSubmit)
        case .web:
            ESMWebView(item: item, onSubmit: onSubmit)
        case .picture:
            ESMPictureView(item: item, onSubmit: onSubmit)
        case .video:
            ESMVideoView(item: item, onSubmit: onSubmit)
        case .audio:
            ESMAudioView(item: item, onSubmit: onSubmit)
        case nil:
            ESMFreeTextView(item: item, onSubmit: onSubmit)
        }
    }
}
