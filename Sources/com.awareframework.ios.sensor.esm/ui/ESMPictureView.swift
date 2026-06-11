import SwiftUI
import PhotosUI

public struct ESMPictureView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selectedImage: UIImage?
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
            ESMPhotoPickerView(image: $selectedImage)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ESMCameraPickerView(image: $selectedImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedImage) { newImage in
            if hideSubmitButton, let img = newImage {
                onSubmit(encodeImage(img) ?? "")
            }
        }
    }

    // MARK: - Sub-views

    private var preview: some View {
        Group {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 160)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 36))
                            Text("No photo selected")
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
                Label("ライブラリ", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if isCameraAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("カメラ", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
    }

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit(selectedImage.flatMap(encodeImage) ?? "")
        }
        .buttonStyle(.borderedProminent)
        .disabled(selectedImage == nil)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func encodeImage(_ image: UIImage) -> String? {
        let resized = image.esm_resized(maxDimension: 800)
        guard let data = resized.jpegData(compressionQuality: 0.6) else { return nil }
        return data.base64EncodedString()
    }
}

// MARK: - Photo library picker (PHPickerViewController, no permission required)

struct ESMPhotoPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ESMPhotoPickerView
        init(_ parent: ESMPhotoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    self?.parent.image = object as? UIImage
                }
            }
        }
    }
}

// MARK: - Camera picker (UIImagePickerController)

struct ESMCameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ESMCameraPickerView
        init(_ parent: ESMCameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIImage resize helper

private extension UIImage {
    func esm_resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
