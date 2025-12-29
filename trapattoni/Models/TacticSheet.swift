import Foundation
import SwiftData
import SwiftUI

// MARK: - Tactic Sheet

@Model
final class TacticSheet {
    var id: UUID = UUID()
    var name: String = "New Tactic"
    var sheetDescription: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var fieldType: FieldType = FieldType.fullField

    @Relationship(deleteRule: .cascade)
    var elements: [BoardElement] = []

    @Relationship(deleteRule: .cascade)
    var drawings: [DrawingPath] = []

    init(
        name: String = "New Tactic",
        sheetDescription: String = "",
        fieldType: FieldType = .fullField
    ) {
        self.id = UUID()
        self.name = name
        self.sheetDescription = sheetDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.fieldType = fieldType
        self.elements = []
        self.drawings = []
    }
}

// MARK: - Field Type

enum FieldType: String, Codable, CaseIterable {
    case fullField = "Full Field"
    case halfField = "Half Field"
    case thirdField = "Third Field"
    case penaltyBox = "Penalty Box"

    /// Aspect ratio (width / height) - portrait orientation with goals at top/bottom
    var aspectRatio: CGFloat {
        switch self {
        case .fullField: return 0.65   // Full pitch (68m / 105m)
        case .halfField: return 0.80   // Half pitch (wider relative to height)
        case .thirdField: return 0.95  // Third of pitch
        case .penaltyBox: return 1.1   // Penalty area (wider than tall)
        }
    }
}

// MARK: - Board Element

@Model
final class BoardElement {
    var id: UUID = UUID()
    var elementType: ElementType = ElementType.player
    var positionX: Double = 0.5
    var positionY: Double = 0.5
    var rotation: Double = 0
    var scale: Double = 1.0
    var label: String = ""
    var teamColor: TeamColor = TeamColor.home
    var number: Int? = nil
    var zIndex: Int = 0

    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }

    init(
        elementType: ElementType,
        position: CGPoint,
        rotation: Double = 0,
        scale: Double = 1.0,
        label: String = "",
        teamColor: TeamColor = .home,
        number: Int? = nil,
        zIndex: Int = 0
    ) {
        self.id = UUID()
        self.elementType = elementType
        self.positionX = position.x
        self.positionY = position.y
        self.rotation = rotation
        self.scale = scale
        self.label = label
        self.teamColor = teamColor
        self.number = number
        self.zIndex = zIndex
    }
}

// MARK: - Element Type

enum ElementType: String, Codable, CaseIterable {
    case player = "Player"
    case goalkeeper = "Goalkeeper"
    case ball = "Ball"
    case cone = "Cone"
    case flag = "Flag"
    case mannequin = "Mannequin"
    case ladder = "Ladder"
    case goal = "Goal"
    case miniGoal = "Mini Goal"

    var icon: String {
        switch self {
        case .player: return "person.fill"
        case .goalkeeper: return "person.fill.checkmark"
        case .ball: return "circle.fill"
        case .cone: return "triangle.fill"
        case .flag: return "flag.fill"
        case .mannequin: return "figure.stand"
        case .ladder: return "square.split.2x2"
        case .goal: return "rectangle.portrait"
        case .miniGoal: return "rectangle"
        }
    }
}

// MARK: - Team Color

enum TeamColor: String, Codable, CaseIterable {
    case home = "Home"
    case away = "Away"
    case neutral = "Neutral"
    case coach = "Coach"

    var color: Color {
        switch self {
        case .home: return .blue
        case .away: return .red
        case .neutral: return .gray
        case .coach: return .orange
        }
    }

    var secondaryColor: Color {
        switch self {
        case .home: return .cyan
        case .away: return .pink
        case .neutral: return .secondary
        case .coach: return .yellow
        }
    }
}

// MARK: - Drawing Path

@Model
final class DrawingPath {
    var id: UUID = UUID()
    var pathType: PathType = PathType.arrow
    var points: [PathPoint] = []
    var strokeColor: StrokeColor = StrokeColor.white
    var strokeWidth: Double = 3
    var isDashed: Bool = false
    var hasArrowHead: Bool = false
    var fillOpacity: Double = 0
    var zIndex: Int = 0

    init(
        pathType: PathType,
        points: [PathPoint] = [],
        strokeColor: StrokeColor = .white,
        strokeWidth: Double = 3,
        isDashed: Bool = false,
        hasArrowHead: Bool = false,
        fillOpacity: Double = 0,
        zIndex: Int = 0
    ) {
        self.id = UUID()
        self.pathType = pathType
        self.points = points
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.isDashed = isDashed
        self.hasArrowHead = hasArrowHead
        self.fillOpacity = fillOpacity
        self.zIndex = zIndex
    }
}

// MARK: - Path Point

struct PathPoint: Codable, Hashable {
    var x: Double
    var y: Double

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
}

// MARK: - Path Type

enum PathType: String, Codable, CaseIterable {
    case arrow = "Arrow"
    case line = "Line"
    case curvedArrow = "Curved Arrow"
    case zone = "Zone"
    case freehand = "Freehand"
    case dottedRun = "Dotted Run"
    case passLine = "Pass Line"

    var icon: String {
        switch self {
        case .arrow: return "arrow.right"
        case .line: return "line.diagonal"
        case .curvedArrow: return "arrow.turn.up.right"
        case .zone: return "square.dashed"
        case .freehand: return "pencil.tip"
        case .dottedRun: return "ellipsis"
        case .passLine: return "arrow.left.and.right"
        }
    }

    var description: String {
        switch self {
        case .arrow: return "Movement Arrow"
        case .line: return "Straight Line"
        case .curvedArrow: return "Curved Run"
        case .zone: return "Highlight Zone"
        case .freehand: return "Free Drawing"
        case .dottedRun: return "Player Run"
        case .passLine: return "Pass Direction"
        }
    }
}

// MARK: - Stroke Color

enum StrokeColor: String, Codable, CaseIterable {
    case white = "White"
    case yellow = "Yellow"
    case red = "Red"
    case blue = "Blue"
    case green = "Green"
    case orange = "Orange"
    case purple = "Purple"
    case black = "Black"

    var color: Color {
        switch self {
        case .white: return .white
        case .yellow: return .yellow
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .black: return .black
        }
    }
}

// MARK: - Tool Selection

enum BoardTool: String, CaseIterable, Identifiable {
    case select = "Select"
    case player = "Player"
    case goalkeeper = "Goalkeeper"
    case ball = "Ball"
    case equipment = "Equipment"
    case arrow = "Arrow"
    case line = "Line"
    case curvedArrow = "Curved"
    case zone = "Zone"
    case freehand = "Draw"
    case eraser = "Eraser"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .select: return "hand.point.up.left"
        case .player: return "person.fill"
        case .goalkeeper: return "person.fill.checkmark"
        case .ball: return "circle.fill"
        case .equipment: return "triangle.fill"
        case .arrow: return "arrow.right"
        case .line: return "line.diagonal"
        case .curvedArrow: return "arrow.turn.up.right"
        case .zone: return "square.dashed"
        case .freehand: return "pencil.tip"
        case .eraser: return "eraser"
        }
    }

    var isDrawingTool: Bool {
        switch self {
        case .arrow, .line, .curvedArrow, .zone, .freehand:
            return true
        default:
            return false
        }
    }
}
