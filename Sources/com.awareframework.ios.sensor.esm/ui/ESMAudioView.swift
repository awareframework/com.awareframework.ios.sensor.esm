import SwiftUI
import AVFoundation

public struct ESMAudioView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var recorder: AVAudioRecorder?
    @State private var player: AVAudioPlayer?
    @State private var recordingURL: URL?
    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var elapsed: TimeInterval = 0
    @State private var ticker: Timer?
    @State private var permissionDenied = false
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 20) {
            waveformArea
            recordButton
            if recordingURL != nil {
                playbackRow
            }
            if !hideSubmitButton {
                submitButton
            }
        }
        .padding(.horizontal)
        .onDisappear { stopAll() }
    }

    // MARK: - Waveform / status area

    private var waveformArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 80)

            if isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 3, height: CGFloat.random(in: 8...48))
                            .animation(
                                .easeInOut(duration: 0.3)
                                    .repeatForever()
                                    .delay(Double(i) * 0.05),
                                value: isRecording
                            )
                    }
                }
            } else if recordingURL != nil {
                Label(
                    timeString(elapsed),
                    systemImage: "waveform"
                )
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
            } else {
                Text("Tap record to start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if isRecording {
                VStack {
                    Spacer()
                    HStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        Text(timeString(elapsed))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
                .frame(height: 80)
            }
        }
    }

    // MARK: - Record button

    private var recordButton: some View {
        Button {
            if isRecording { stopRecording() } else { startRecording() }
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color(.systemGray5))
                    .frame(width: 72, height: 72)
                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 52, height: 52)
                }
            }
        }
        .disabled(permissionDenied)
        .overlay(alignment: .bottom) {
            Text(isRecording ? "Stop" : "Record")
                .font(.caption)
                .foregroundStyle(.secondary)
                .offset(y: 20)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Playback row

    private var playbackRow: some View {
        HStack(spacing: 16) {
            Button {
                if isPlaying { stopPlayback() } else { startPlayback() }
            } label: {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(isPlaying ? .orange : .accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Recorded")
                    .font(.subheadline)
                Text(timeString(elapsed))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                deleteRecording()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit(recordingURL?.path ?? "")
        }
        .buttonStyle(.borderedProminent)
        .disabled(recordingURL == nil)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Recording logic

    private func startRecording() {
        requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    permissionDenied = true
                    return
                }
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default)
                    try session.setActive(true)

                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("esm_audio_\(UUID().uuidString).m4a")
                    let settings: [String: Any] = [
                        AVFormatIDKey:            Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey:          44100,
                        AVNumberOfChannelsKey:    1,
                        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
                    ]
                    recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder?.record()
                    recordingURL = url
                    isRecording = true
                    elapsed = 0
                    startTicker()
                } catch {
                    print("ESMAudioView: record error:", error)
                }
            }
        }
    }

    private func requestRecordPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission(completion)
        }
    }

    private func stopRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        stopTicker()
        try? AVAudioSession.sharedInstance().setActive(false)
        if hideSubmitButton, let url = recordingURL {
            onSubmit(url.path)
        }
    }

    // MARK: - Playback logic

    private func startPlayback() {
        guard let url = recordingURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            isPlaying = true
        } catch {
            print("ESMAudioView: playback error:", error)
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    private func deleteRecording() {
        stopPlayback()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
        elapsed = 0
    }

    private func stopAll() {
        stopRecording()
        stopPlayback()
    }

    // MARK: - Timer

    private func startTicker() {
        ticker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            elapsed += 0.5
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: - Helpers

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
