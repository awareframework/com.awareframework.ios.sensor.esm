import SwiftUI
import WebKit

public struct ESMWebView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void
    let fillsAvailableSpace: Bool

    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(
        item: ESMItem,
        fillsAvailableSpace: Bool = false,
        onSubmit: @escaping (String) -> Void
    ) {
        self.item = item
        self.fillsAvailableSpace = fillsAvailableSpace
        self.onSubmit = onSubmit
    }

    public var body: some View {
        if fillsAvailableSpace {
            fullScreenBody
        } else {
            standardBody
        }
    }

    private var standardBody: some View {
        VStack(spacing: 12) {
            if let urlString = item.esmUrl, let url = URL(string: urlString) {
                ESMWKWebView(url: url)
                    .frame(minHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Invalid URL")
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 200)
            }

            if !hideSubmitButton {
                Button(item.esmSubmit ?? "OK") {
                    onSubmit("completed")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
        .onAppear {
            if hideSubmitButton { onSubmit("completed") }
        }
    }

    private var fullScreenBody: some View {
        Group {
            if let urlString = item.esmUrl, let url = URL(string: urlString) {
                ESMWKWebView(url: url)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Invalid URL")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            if hideSubmitButton { onSubmit("completed") }
        }
    }
}

// MARK: - WKWebView wrapper

struct ESMWKWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
