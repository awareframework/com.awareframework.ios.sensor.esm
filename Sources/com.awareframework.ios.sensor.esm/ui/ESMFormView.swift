import SwiftUI

/// Presents ESM questions in one of two layouts driven by `schedule.interface`:
/// - `nil` / `0` — one-by-one mode: one question at a time with slide animation and a progress bar.
/// - `1`         — single-line mode: all questions stacked vertically in a scroll view; one Submit button at the bottom.
public struct ESMFormView: View {

    let schedule: ESMSchedule
    let notificationTime: Int64
    let onCompleted: ([String: String]) -> Void
    let onDismissed: () -> Void

    @State private var currentIndex: Int = 0
    @State private var answers: [String: String] = [:]
    @State private var showUnansweredAlert = false
    @State private var unansweredCount = 0

    private var isSingleLine: Bool { schedule.interface == 1 }

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
        let skipValidation = item.esmType == ESMType.web.rawValue
                         || item.esmType == ESMType.quickAnswer.rawValue
        return ESMQuestionView(item: item) { answer in
            if !skipValidation && answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                unansweredCount = 1
                showUnansweredAlert = true
                return
            }
            let key = item.esmTrigger ?? "\(currentIndex)"
            answers[key] = answer
            advance()
        }
        .id(currentIndex)
        .transition(.asymmetric(
            insertion:  .move(edge: .trailing),
            removal:    .move(edge: .leading)
        ))
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
            withAnimation { currentIndex += 1 }
        } else {
            onCompleted(answers)
        }
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

                Button("Submit") {
                    submitAll()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func submitAll() {
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
