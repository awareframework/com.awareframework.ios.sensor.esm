import SwiftUI

/// Presents ESM questions in one of two layouts driven by `schedule.interface`:
/// - `nil` / `0` — one-by-one mode: one question at a time with slide animation and a progress bar.
/// - `1`         — single-line mode: all questions stacked vertically in a scroll view; one Submit button at the bottom.
public struct ESMFormView: View {
    private enum QuestionNavigationDirection {
        case forward
        case backward
    }

    let schedule: ESMSchedule
    let notificationTime: Int64
    let onCompleted: ([String: String]) -> Void
    let onDismissed: () -> Void

    @State private var currentIndex: Int = 0
    @State private var answers: [String: String] = [:]
    @State private var showUnansweredAlert = false
    @State private var unansweredCount = 0
    @State private var isNotApplicable = false
    @State private var currentNotApplicable = false
    @State private var navigationDirection: QuestionNavigationDirection = .forward

    private var isSingleLine: Bool { schedule.interface == 1 }
    private var submitTitle: String { scheduleTitle(\.esmSubmit, fallback: "Submit") }
    private var backTitle: String { scheduleTitle(\.esmBack, fallback: "Back") }
    private var showsNotApplicable: Bool {
        schedule.esms.contains { ($0.esm.esmNa ?? 0) != 0 }
    }
    private var questionTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }

    public init(
        schedule: ESMSchedule,
        notificationTime: Int64 = 0,
        onCompleted: @escaping ([String: String]) -> Void,
        onDismissed: @escaping () -> Void
    ) {
        self.schedule = schedule
        self.notificationTime = notificationTime
        self.onCompleted = onCompleted
        self.onDismissed = onDismissed
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if schedule.esms.isEmpty {
                    emptyView
                } else if isSingleLine {
                    singleLineBody
                } else {
                    oneByOneQuestion
                    progressFooter
                }
            }
            .navigationTitle(schedule.notificationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { dismissButton }
        }
        .alert("未入力の項目があります", isPresented: $showUnansweredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("すべての質問に回答してから送信してください。(\(unansweredCount)件未回答)")
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Questions")
                .font(.headline)
            Text("This schedule contains no questions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - One-by-one mode

    private var oneByOneQuestion: some View {
        let item = schedule.esms[currentIndex].esm
        let key = item.esmTrigger ?? "\(currentIndex)"

        return VStack(spacing: 12) {
            ESMQuestionView(item: item) { answer in
                answers[key] = answer
                if answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    currentNotApplicable = false
                }
            }
            .environment(\.esmHideSubmitButton, true)

            if itemAllowsNotApplicable(item) {
                notApplicableCheckbox(isChecked: $currentNotApplicable)
                    .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                Button {
                    backFromCurrentQuestion()
                } label: {
                    Text(backTitle(for: item))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                Button {
                    submitCurrentQuestion(item: item, key: key)
                } label: {
                    Text(submitTitle(for: item))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear {
            syncCurrentNotApplicable(key: key)
        }
        .onChange(of: currentIndex) { _ in
            let current = schedule.esms[currentIndex].esm
            syncCurrentNotApplicable(key: current.esmTrigger ?? "\(currentIndex)")
        }
        .id(currentIndex)
        .transition(questionTransition)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }

    private var progressFooter: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentIndex + 1), total: Double(schedule.esms.count))
                .progressViewStyle(.linear)
                .padding(.horizontal)
            Text("\(currentIndex + 1) of \(schedule.esms.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private func advance() {
        if currentIndex < schedule.esms.count - 1 {
            navigationDirection = .forward
            withAnimation { currentIndex += 1 }
        } else {
            onCompleted(answers)
        }
    }

    private func backFromCurrentQuestion() {
        if currentIndex > 0 {
            navigationDirection = .backward
            withAnimation { currentIndex -= 1 }
        } else {
            onDismissed()
        }
    }

    private func submitCurrentQuestion(item: ESMItem, key: String) {
        if currentNotApplicable && itemAllowsNotApplicable(item) {
            answers[key] = "NA"
            advance()
            return
        }

        let answer = answers[key] ?? ""
        if shouldValidate(item) && answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            unansweredCount = 1
            showUnansweredAlert = true
            return
        }

        advance()
    }

    private func shouldValidate(_ item: ESMItem) -> Bool {
        item.esmType != ESMType.web.rawValue
    }

    private func syncCurrentNotApplicable(key: String) {
        currentNotApplicable = answers[key] == "NA"
    }

    // MARK: - Single-line mode

    private var singleLineBody: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(schedule.esms.indices, id: \.self) { index in
                    let wrapper = schedule.esms[index]
                    SingleLineQuestionRow(
                        index: index,
                        total: schedule.esms.count,
                        item: wrapper.esm,
                        onAnswer: { answer in
                            let key = wrapper.esm.esmTrigger ?? "\(index)"
                            answers[key] = answer
                        }
                    )
                }

                if showsNotApplicable {
                    notApplicableCheckbox(isChecked: $isNotApplicable)
                    .padding(.top, 4)
                }

                HStack(spacing: 12) {
                    Button {
                        onDismissed()
                    } label: {
                        Text(backTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        submitAll()
                    } label: {
                        Text(submitTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func trimmed(_ value: String?, fallback: String) -> String {
        let text = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? fallback : text
    }

    private func scheduleTitle(_ keyPath: KeyPath<ESMItem, String?>, fallback: String) -> String {
        for wrapper in schedule.esms {
            let text = trimmed(wrapper.esm[keyPath: keyPath], fallback: "")
            if text.isEmpty == false {
                return text
            }
        }
        return fallback
    }

    private func submitTitle(for item: ESMItem) -> String {
        trimmed(item.esmSubmit, fallback: submitTitle)
    }

    private func backTitle(for item: ESMItem) -> String {
        trimmed(item.esmBack, fallback: backTitle)
    }

    private func itemAllowsNotApplicable(_ item: ESMItem) -> Bool {
        (item.esmNa ?? 0) != 0
    }

    private func notApplicableCheckbox(isChecked: Binding<Bool>) -> some View {
        Button {
            isChecked.wrappedValue.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isChecked.wrappedValue ? Color.accentColor : Color.secondary)
                Text("NA")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func submitNotApplicable() {
        for (index, wrapper) in schedule.esms.enumerated() {
            let key = wrapper.esm.esmTrigger ?? "\(index)"
            answers[key] = "NA"
        }
        onCompleted(answers)
    }

    private func submitAll() {
        if isNotApplicable {
            submitNotApplicable()
            return
        }

        let missing = schedule.esms.enumerated().filter { (index, wrapper) in
            let key = wrapper.esm.esmTrigger ?? "\(index)"
            let answer = answers[key] ?? ""
            return answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard missing.isEmpty else {
            unansweredCount = missing.count
            showUnansweredAlert = true
            return
        }

        onCompleted(answers)
    }

    // MARK: - Toolbar

    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Dismiss", role: .cancel) { onDismissed() }
        }
    }
}

// MARK: - Single-line row

private struct SingleLineQuestionRow: View {
    let index: Int
    let total: Int
    let item: ESMItem
    let onAnswer: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack {
                Text("Q\(index + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor, in: Capsule())

                Spacer()

                Text("\(index + 1) / \(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            ESMQuestionView(item: item, onSubmit: onAnswer, isEmbedded: true)
                .environment(\.esmHideSubmitButton, true)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
