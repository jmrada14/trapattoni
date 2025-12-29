import SwiftUI
import WebKit

struct VideoPlayerView: View {
    let urlString: String

    private var embedURL: URL? {
        YouTubeURLParser.embedURL(from: urlString)
    }

    var body: some View {
        if let url = embedURL {
            YouTubeWebView(url: url)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ContentUnavailableView(
                "Video Unavailable",
                systemImage: "video.slash",
                description: Text("Unable to load video")
            )
        }
    }
}

// MARK: - Platform-specific WebView

#if os(iOS)
struct YouTubeWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#else
struct YouTubeWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
#endif

#Preview {
    VideoPlayerView(urlString: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        .frame(height: 220)
        .padding()
}
