import Foundation

enum SessionTemplateType: String, Codable, CaseIterable, Identifiable {
    case warmUp = "Warm-Up"
    case quickSession = "Quick Session"
    case fullWorkout = "Full Workout"
    case skillFocus = "Skill Focus"
    case custom = "Custom"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .warmUp: return "flame"
        case .quickSession: return "bolt"
        case .fullWorkout: return "figure.run"
        case .skillFocus: return "target"
        case .custom: return "slider.horizontal.3"
        }
    }

    var suggestedDurationMinutes: Int {
        switch self {
        case .warmUp: return 10
        case .quickSession: return 20
        case .fullWorkout: return 45
        case .skillFocus: return 30
        case .custom: return 30
        }
    }

    var suggestedExerciseCount: Int {
        switch self {
        case .warmUp: return 3
        case .quickSession: return 4
        case .fullWorkout: return 8
        case .skillFocus: return 5
        case .custom: return 5
        }
    }

    var description: String {
        switch self {
        case .warmUp: return "Quick warm-up routine to get ready"
        case .quickSession: return "Short focused training when time is limited"
        case .fullWorkout: return "Complete training session with variety"
        case .skillFocus: return "Deep practice on a specific skill area"
        case .custom: return "Build your own custom session"
        }
    }
}
