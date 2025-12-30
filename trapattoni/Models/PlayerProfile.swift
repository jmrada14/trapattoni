import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var id: UUID = UUID()
    var name: String = ""
    var bio: String = ""
    var photoData: Data?
    var position: String = ""
    var preferredFoot: String = "right"
    var yearsPlaying: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Goals and preferences
    var weeklyGoalSessions: Int = 3
    var focusAreas: [String] = []

    // Notification preferences
    var notificationsEnabled: Bool = true
    var inactivityRemindersEnabled: Bool = true
    var inactivityDaysThreshold: Int = 3
    var weeklyGoalRemindersEnabled: Bool = true
    var reminderHour: Int = 9
    var reminderMinute: Int = 0

    // Language preference
    var languageCode: String = "en"

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageCode) ?? .english }
        set { languageCode = newValue.rawValue }
    }

    // Computed property for reminder time
    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 9
            reminderMinute = components.minute ?? 0
        }
    }

    init(
        name: String = "",
        bio: String = "",
        photoData: Data? = nil,
        position: String = "",
        preferredFoot: String = "right",
        yearsPlaying: Int = 0,
        weeklyGoalSessions: Int = 3,
        focusAreas: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.bio = bio
        self.photoData = photoData
        self.position = position
        self.preferredFoot = preferredFoot
        self.yearsPlaying = yearsPlaying
        self.weeklyGoalSessions = weeklyGoalSessions
        self.focusAreas = focusAreas
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Player Position

enum PlayerPosition: String, CaseIterable, Identifiable {
    case goalkeeper = "Goalkeeper"
    case defender = "Defender"
    case midfielder = "Midfielder"
    case forward = "Forward"
    case winger = "Winger"
    case striker = "Striker"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .goalkeeper: return "hand.raised.fill"
        case .defender: return "shield.fill"
        case .midfielder: return "circle.grid.cross.fill"
        case .forward: return "arrow.up.circle.fill"
        case .winger: return "arrow.left.and.right.circle.fill"
        case .striker: return "target"
        case .other: return "person.fill"
        }
    }

    var localizedName: String {
        switch self {
        case .goalkeeper: return "position.goalkeeper".localized
        case .defender: return "position.defender".localized
        case .midfielder: return "position.midfielder".localized
        case .forward: return "position.forward".localized
        case .winger: return "position.winger".localized
        case .striker: return "position.striker".localized
        case .other: return "position.other".localized
        }
    }
}

// MARK: - Preferred Foot

enum PreferredFoot: String, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"
    case both = "Both"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .left: return "foot.left".localized
        case .right: return "foot.right".localized
        case .both: return "foot.both".localized
        }
    }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt-BR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português (Brasil)"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .portuguese: return "🇧🇷"
        }
    }

    var voiceLanguageCode: String {
        switch self {
        case .english: return "en-US"
        case .spanish: return "es-ES"
        case .portuguese: return "pt-BR"
        }
    }
}
