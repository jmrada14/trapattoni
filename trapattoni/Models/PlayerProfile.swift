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
}

// MARK: - Preferred Foot

enum PreferredFoot: String, CaseIterable, Identifiable {
    case left = "Left"
    case right = "Right"
    case both = "Both"

    var id: String { rawValue }
}
