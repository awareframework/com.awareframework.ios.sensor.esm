import SwiftUI
import PhotosUI
import AVKit

public struct ESMVideoView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 16) {
            preview
            actionButtons
            if !hideSubmitButton {
                submitButton
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ESMVideoPickerView(videoURL: $videoURL, player: $player)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ESMVideoCameraView(videoURL: $videoURL, player: $player)
                .ignoresSafeArea()
        }
        .onChange(of: videoURL) { newURL in
            if hideSubmitButton, let url = newURL {
                onSubmit(encodeVideo(url) ?? "")
            }
        }
    }

    // MARK: - Sub-views

    private var preview: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 160)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "video")
                                .font(.system(size: 36))
                            Text("No video selected")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            }
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showPhotoPicker = true
            } label: {
                Label("Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if isCameraAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "video.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit(videoURL.flatMap(encodeVideo) ?? "")
        }
        .buttonStyle(.borderedProminent)
        .disabled(videoURL == nil)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func encodeVideo(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return data.base64EncodedString()
    }
}

// MARK: - Photo library picker (PHPickerViewController)

struct ESMVideoPickerView: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Binding var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ESMVideoPickerView
        init(_ parent: ESMVideoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier("public.movie") else { return }

            provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { [weak self] url, _ in
                guard let url, let self else { return }
                let dest = self.copyToTemp(url)
                DispatchQueue.main.async {
                    self.parent.videoURL = dest
                    self.parent.player = dest.map { AVPlayer(url: $0) }
                }
            }
        }

        private func copyToTemp(_ source: URL) -> URL? {
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("esm_video_\(UUID().uuidString).mov")
            do {
                try FileManager.default.copyItem(at: source, to: dest)
                return dest
            } catch {
                return nil
            }
        }
    }
}

// MARK: - Camera recorder (UIImagePickerController)

struct ESMVideoCameraView: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    @Binding var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeMedium
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ESMVideoCameraView
        init(_ parent: ESMVideoCameraView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let url = info[.mediaURL] as? URL {
                let dest = copyToTemp(url)
                parent.videoURL = dest
                parent.player = dest.map { AVPlayer(url: $0) }
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        private func copyToTemp(_ source: URL) -> URL? {
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent("esm_video_\(UUID().uuidString).mov")
            do {
                try FileManager.default.copyItem(at: source, to: dest)
                return dest
            } catch {
                return nil
            }
        }
    }
}
