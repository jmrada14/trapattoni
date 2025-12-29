import SwiftUI

extension Color {
    /// Cross-platform primary background color
    static var systemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Cross-platform secondary background color
    static var secondaryBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Cross-platform tertiary background color
    static var tertiaryBackground: Color {
        #if os(iOS)
        Color(.tertiarySystemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Cross-platform gray5 color
    static var systemGray5: Color {
        #if os(iOS)
        Color(.systemGray5)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }

    /// Cross-platform gray6 color
    static var systemGray6: Color {
        #if os(iOS)
        Color(.systemGray6)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
