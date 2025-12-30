import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case dribbling = "Dribbling"
    case passing = "Passing"
    case shooting = "Shooting"
    case firstTouch = "First Touch"
    case fitnessConditioning = "Fitness & Conditioning"
    case goalkeeping = "Goalkeeping"
    case defending = "Defending"
    case setPieces = "Set Pieces"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dribbling: return "figure.run"
        case .passing: return "arrow.left.arrow.right"
        case .shooting: return "target"
        case .firstTouch: return "hand.raised"
        case .fitnessConditioning: return "heart.fill"
        case .goalkeeping: return "hand.raised.fill"
        case .defending: return "shield.fill"
        case .setPieces: return "flag.fill"
        }
    }

    var localizedName: String {
        switch self {
        case .dribbling: return "category.dribbling".localized
        case .passing: return "category.passing".localized
        case .shooting: return "category.shooting".localized
        case .firstTouch: return "category.firstTouch".localized
        case .fitnessConditioning: return "category.fitness".localized
        case .goalkeeping: return "category.goalkeeping".localized
        case .defending: return "category.defending".localized
        case .setPieces: return "category.setPieces".localized
        }
    }
}

enum TrainingType: String, Codable, CaseIterable, Identifiable {
    case solo = "Solo"
    case partner = "Partner"
    case team = "Team"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .solo: return "person.fill"
        case .partner: return "person.2.fill"
        case .team: return "person.3.fill"
        }
    }

    var localizedName: String {
        switch self {
        case .solo: return "exercise.individual".localized
        case .partner: return "exercise.partner".localized
        case .team: return "exercise.team".localized
        }
    }
}

enum SkillLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }

    static func < (lhs: SkillLevel, rhs: SkillLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var localizedName: String {
        switch self {
        case .beginner: return "exercise.beginner".localized
        case .intermediate: return "exercise.intermediate".localized
        case .advanced: return "exercise.advanced".localized
        }
    }
}

enum Duration: String, Codable, CaseIterable, Identifiable {
    case short = "Short (5-10 min)"
    case medium = "Medium (10-20 min)"
    case long = "Long (20+ min)"

    var id: String { rawValue }

    var iconName: String { "clock" }

    var localizedName: String {
        switch self {
        case .short: return "duration.short".localized
        case .medium: return "duration.medium".localized
        case .long: return "duration.long".localized
        }
    }
}

enum SpaceRequired: String, Codable, CaseIterable, Identifiable {
    case small = "Small (5x5m)"
    case medium = "Medium (10x10m)"
    case large = "Large (20x20m+)"

    var id: String { rawValue }

    var iconName: String { "square.dashed" }

    var localizedName: String {
        switch self {
        case .small: return "space.small".localized
        case .medium: return "space.medium".localized
        case .large: return "space.large".localized
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case ball = "Ball"
    case cones = "Cones"
    case goal = "Goal"
    case wall = "Wall"
    case ladder = "Agility Ladder"
    case hurdles = "Hurdles"
    case resistanceBand = "Resistance Band"
    case poles = "Poles"
    case mannequin = "Training Mannequin"
    case rebounder = "Rebounder"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .ball: return "circle.fill"
        case .cones: return "cone.fill"
        case .goal: return "rectangle.3.group"
        case .wall: return "rectangle.fill"
        case .ladder: return "rectangle.split.3x3"
        case .hurdles: return "figure.gymnastics"
        case .resistanceBand: return "circle.and.line.horizontal"
        case .poles: return "lines.measurement.vertical"
        case .mannequin: return "figure.stand"
        case .rebounder: return "arrow.uturn.backward"
        }
    }

    var localizedName: String {
        switch self {
        case .ball: return "equipment.ball".localized
        case .cones: return "equipment.cones".localized
        case .goal: return "equipment.goal".localized
        case .wall: return "equipment.wall".localized
        case .ladder: return "equipment.ladder".localized
        case .hurdles: return "equipment.hurdles".localized
        case .resistanceBand: return "equipment.resistanceBand".localized
        case .poles: return "equipment.poles".localized
        case .mannequin: return "equipment.mannequin".localized
        case .rebounder: return "equipment.rebounder".localized
        }
    }
}
