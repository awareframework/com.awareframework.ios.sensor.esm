import SwiftUI

/// Presents ESM questions in one of two layouts driven by `schedule.interface`:
/// - `nil` / `0` — one-by-one mode: one question at a time with slide animation and a progress bar.
/// - `1`         — single-line mode: all questions stacked vertically in a scroll view; one Submit button at the bottom.
///
/// Questions with `esm_flows` add the questions their answer selects right after them (see `ESMFlow`).
/// In one-by-one mode they come next; in single-line mode they appear below the question as soon as
/// it is answered. Changing an answer removes the questions of the branch it no longer selects, and
/// their answers are not passed to `onCompleted`. Use `ESMSensor.submitAnswers(schedule:answers:notificationTime:)`
/// to save the answers of all questions, including those of the branches.
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
    /// The questions to show for the current answers (the schedule's questions and their branches)
    private var entries: [ESMSurveyEntry] { schedule.surveyEntries(answers: answers) }
    private var singlePageWebItem: ESMItem? {
        guard isSingleLine, schedule.esms.count == 1 else { return nil }
        let item = schedule.esms[0].esm
        return item.esmType == ESMType.web.rawValue ? item : nil
    }
    private var isSinglePageWebSurvey: Bool { singlePageWebItem != nil }
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
                } else if isSinglePageWebSurvey {
                    singlePageWebBody
                } else if isSingleLine {
                    singleLineBody
                } else {
                    oneByOneQuestion
                    progressFooter
                }
            }
            .navigationTitle(schedule.notificationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .alert("Missing answers", isPresented: $showUnansweredAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please answer all required questions before submitting. (\(unansweredCount) missing)")
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
        let list = entries
        let entry = list[min(currentIndex, list.count - 1)]
        let item = entry.item
        let key = entry.key

        return VStack(spacing: 12) {
            ESMQuestionView(item: item) { answer in
                answers[key] = answer
                if answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    currentNotApplicable = false
                }
            }
            .environment(\.esmHideSubmitButton, true)
            // Going back to a question shows the answer given before
            .environment(\.esmInitialAnswer, answers[key])

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
                    primarySubmitLabel(submitTitle(for: item))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .shadow(color: Color.accentColor.opacity(0.22), radius: 5, x: 0, y: 3)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear {
            syncCurrentNotApplicable(key: key)
        }
        .onChange(of: currentIndex) { _ in
            let list = entries
            syncCurrentNotApplicable(key: list[min(currentIndex, list.count - 1)].key)
        }
        .id(key)
        .transition(questionTransition)
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }

    private var progressFooter: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentIndex + 1), total: Double(max(entries.count, 1)))
                .progressViewStyle(.linear)
                .padding(.horizontal)
            Text("\(currentIndex + 1) of \(entries.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }

    private func advance() {
        // The list is read after the current answer was stored, so the questions it selected come next
        if currentIndex < entries.count - 1 {
            navigationDirection = .forward
            withAnimation { currentIndex += 1 }
        } else {
            complete()
        }
    }

    /// Pass the answers of the questions that are part of the survey (answers to questions of a
    /// branch that a changed answer no longer selects are dropped).
    private func complete() {
        let keys = Set(entries.map(\.key))
        onCompleted(answers.filter { keys.contains($0.key) })
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

    private var singlePageWebBody: some View {
        let item = singlePageWebItem ?? schedule.esms[0].esm
        let key = item.esmTrigger ?? "0"

        return ESMWebView(item: item, fillsAvailableSpace: true) { answer in
            answers[key] = answer
        }
        .environment(\.esmHideSubmitButton, true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            answers[key] = answers[key] ?? "completed"
        }
    }

    private var singleLineBody: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                let list = entries
                ForEach(Array(list.enumerated()), id: \.element.key) { index, entry in
                    SingleLineQuestionRow(
                        index: index,
                        total: list.count,
                        item: entry.item,
                        depth: entry.depth,
                        onAnswer: { answer in
                            answers[entry.key] = answer
                        }
                    )
                    // A row recreated after scrolling shows its answer again
                    .environment(\.esmInitialAnswer, answers[entry.key])
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
                        primarySubmitLabel(submitTitle)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .shadow(color: Color.accentColor.opacity(0.22), radius: 5, x: 0, y: 3)
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

    private func primarySubmitLabel(_ title: String) -> some View {
        Label {
            Text(title)
                .font(.headline.weight(.semibold))
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
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
        // "NA" selects no branch, so only the schedule's own questions remain
        for entry in entries where entry.depth == 0 {
            answers[entry.key] = ESMFlow.notApplicable
        }
        complete()
    }

    private func submitAll() {
        if isNotApplicable {
            submitNotApplicable()
            return
        }

        let missing = entries.filter { entry in
            let answer = answers[entry.key] ?? ""
            return answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard missing.isEmpty else {
            unansweredCount = missing.count
            showUnansweredAlert = true
            return
        }

        complete()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        dismissButton
        if let item = singlePageWebItem {
            ToolbarItem(placement: .confirmationAction) {
                Button(submitTitle(for: item)) {
                    submitSinglePageWebSurvey(item: item)
                }
            }
        }
    }

    private var dismissButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Dismiss", role: .cancel) { onDismissed() }
        }
    }

    private func submitSinglePageWebSurvey(item: ESMItem) {
        let key = item.esmTrigger ?? "0"
        if answers[key]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            answers[key] = "completed"
        }
        complete()
    }
}

// MARK: - Single-line row

private struct SingleLineQuestionRow: View {
    let index: Int
    let total: Int
    let item: ESMItem
    /// 0 for a question of the schedule, 1 or more for a question selected by an answer (esm_flows)
    var depth: Int = 0
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
        // A question selected by an earlier answer is indented below it
        .padding(.leading, CGFloat(min(depth, 3)) * 16)
    }
}
