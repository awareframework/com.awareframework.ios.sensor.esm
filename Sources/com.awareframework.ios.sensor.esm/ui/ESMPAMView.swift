import SwiftUI

// MARK: - PAMCell

/// One cell in the 4×4 PAM grid.
/// Images are loaded from the smalldatalab/android-pam repository on GitHub.
public struct PAMCell: Identifiable, Equatable {
    /// Sequential number 1–16 matching the folder prefix in the asset repo.
    public let id: Int
    /// Folder name suffix (e.g. "afraid" → folder "1_afraid").
    public let name: String

    public var label: String { name.capitalized }

    /// Raw URL for image variant `imageIndex` (1, 2, or 3).
    public func imageURL(index: Int = 1) -> URL? {
        let folder = "\(id)_\(name)"
        let file   = "\(id)_\(index).jpg"
        return URL(string: "https://raw.githubusercontent.com/smalldatalab/android-pam/master/app/src/main/assets/pam_images/\(folder)/\(file)")
    }
}

// MARK: - Image Cache

private final class PAMImageCache {
    static let shared = PAMImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }

    func prefetch(urls: [URL]) {
        for url in urls where image(for: url) == nil {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let img = UIImage(data: data) else { return }
                self?.store(img, for: url)
            }.resume()
        }
    }
}

// MARK: - Square cached image

private struct PAMSquareImage: View {
    let url: URL?
    @State private var uiImage: UIImage?
    @State private var failed = false

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let img = uiImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if failed {
                    Color(.systemGray4)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                } else {
                    Color(.systemGray6)
                        .overlay { ProgressView().scaleEffect(0.5) }
                }
            }
            .clipped()
            .onAppear(perform: load)
    }

    private func load() {
        guard let url else { failed = true; return }
        if let cached = PAMImageCache.shared.image(for: url) {
            uiImage = cached
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                if let data, let img = UIImage(data: data) {
                    PAMImageCache.shared.store(img, for: url)
                    uiImage = img
                } else {
                    failed = true
                }
            }
        }.resume()
    }
}

// MARK: - PAM view

/// Photographic Affect Meter (PAM) — 4×4 grid of affect photos from the
/// circumplex model of affect (valence × arousal).
///
/// Images: https://github.com/smalldatalab/android-pam
/// Paper:  Pollak et al. (2011) https://dl.acm.org/doi/10.1145/1978942.1979047
public struct ESMPAMView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var selected: PAMCell?
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
    }

    // MARK: - Grid definition
    // Row order: high arousal (top) → low arousal (bottom)
    // Column order: unpleasant (left) → pleasant (right)

    private let cells: [[PAMCell]] = [
        [PAMCell(id:  1, name: "afraid"),     PAMCell(id:  2, name: "tense"),
         PAMCell(id:  3, name: "excited"),    PAMCell(id:  4, name: "delighted")  ],
        [PAMCell(id:  5, name: "frustrated"), PAMCell(id:  6, name: "angry"),
         PAMCell(id:  7, name: "happy"),      PAMCell(id:  8, name: "glad")       ],
        [PAMCell(id:  9, name: "miserable"),  PAMCell(id: 10, name: "sad"),
         PAMCell(id: 11, name: "calm"),       PAMCell(id: 12, name: "satisfied")  ],
        [PAMCell(id: 13, name: "gloomy"),     PAMCell(id: 14, name: "tired"),
         PAMCell(id: 15, name: "sleepy"),     PAMCell(id: 16, name: "serene")     ],
    ]

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 8) {
            pamGrid
            if !hideSubmitButton {
                submitButton
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            PAMImageCache.shared.prefetch(urls: cells.flatMap { $0 }.compactMap { $0.imageURL() })
        }
    }

    // MARK: - Axis labels

    private var arousalTopLabel: some View {
        Label("High Arousal", systemImage: "arrow.up")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.primary)
    }

    private var arousalBottomLabel: some View {
        Label("Low Arousal", systemImage: "arrow.down")
            .font(.footnote.weight(.medium))
            .foregroundStyle(.primary)
    }

    private func valenceLabel(_ text: String, angle: Double) -> some View {
        Label(text, systemImage: "arrow.up")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.primary)
            .fixedSize()
            .rotationEffect(.degrees(angle))
            .frame(width: 18)
    }

    // MARK: - Grid

    private let cellSize: CGFloat = 70

    private var pamGrid: some View {
        VStack(spacing: 2) {
            ForEach(0..<cells.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(cells[row]) { cell in
                        pamCell(cell)
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
    }

    private func pamCell(_ cell: PAMCell) -> some View {
        let isSelected = selected?.id == cell.id
        return Button {
            selected = cell
            if hideSubmitButton { onSubmit(cell.label) }
        } label: {
            PAMSquareImage(url: cell.imageURL())
                .overlay {
                    Rectangle()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            if let cell = selected { onSubmit(cell.label) }
        }
        .buttonStyle(.borderedProminent)
        .disabled(selected == nil)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}