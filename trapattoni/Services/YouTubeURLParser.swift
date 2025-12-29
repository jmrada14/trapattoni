import Foundation

enum YouTubeURLParser {
    /// Extracts the video ID from various YouTube URL formats
    static func videoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // Handle youtu.be short links
        if url.host?.contains("youtu.be") == true {
            return url.pathComponents.dropFirst().first
        }

        // Handle youtube.com URLs
        if url.host?.contains("youtube.com") == true {
            // Handle /watch?v= format
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }

            // Handle /embed/ format
            if url.pathComponents.contains("embed"),
               let index = url.pathComponents.firstIndex(of: "embed"),
               url.pathComponents.count > index + 1 {
                return url.pathComponents[index + 1]
            }

            // Handle /v/ format
            if url.pathComponents.contains("v"),
               let index = url.pathComponents.firstIndex(of: "v"),
               url.pathComponents.count > index + 1 {
                return url.pathComponents[index + 1]
            }
        }

        return nil
    }

    /// Generates an embed URL from a YouTube video URL
    static func embedURL(from urlString: String) -> URL? {
        guard let videoID = videoID(from: urlString) else { return nil }
        return URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1")
    }

    /// Generates a thumbnail URL from a YouTube video URL
    static func thumbnailURL(from urlString: String, quality: ThumbnailQuality = .medium) -> URL? {
        guard let videoID = videoID(from: urlString) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(videoID)/\(quality.rawValue).jpg")
    }

    enum ThumbnailQuality: String {
        case low = "default"
        case medium = "mqdefault"
        case high = "hqdefault"
        case max = "maxresdefault"
    }
}
