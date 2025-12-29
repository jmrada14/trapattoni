import Foundation
import SwiftUI

// MARK: - Field Position

struct FieldPosition: Equatable, Sendable {
    var x: CGFloat  // 0.0 to 1.0 (normalized)
    var y: CGFloat  // 0.0 to 1.0 (normalized)

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    // Common positions
    static let center = FieldPosition(x: 0.5, y: 0.5)
    static let topCenter = FieldPosition(x: 0.5, y: 0.15)
    static let bottomCenter = FieldPosition(x: 0.5, y: 0.85)
    static let leftCenter = FieldPosition(x: 0.15, y: 0.5)
    static let rightCenter = FieldPosition(x: 0.85, y: 0.5)
    static let topLeft = FieldPosition(x: 0.2, y: 0.2)
    static let topRight = FieldPosition(x: 0.8, y: 0.2)
    static let bottomLeft = FieldPosition(x: 0.2, y: 0.8)
    static let bottomRight = FieldPosition(x: 0.8, y: 0.8)

    // Goal positions
    static let goalCenter = FieldPosition(x: 0.5, y: 0.08)
    static let goalLeft = FieldPosition(x: 0.35, y: 0.08)
    static let goalRight = FieldPosition(x: 0.65, y: 0.08)

    // Convert to actual point in canvas
    func toPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }

    // Interpolate between two positions
    func interpolated(to target: FieldPosition, progress: CGFloat) -> FieldPosition {
        FieldPosition(
            x: x + (target.x - x) * progress,
            y: y + (target.y - y) * progress
        )
    }

    // Distance to another position
    func distance(to other: FieldPosition) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }

    // Angle to another position (in radians)
    func angle(to other: FieldPosition) -> CGFloat {
        atan2(other.y - y, other.x - x)
    }
}

// MARK: - Movement Path

struct MovementPath: Identifiable, Sendable {
    let id = UUID()
    let waypoints: [FieldPosition]
    let duration: TimeInterval
    let repeatBehavior: RepeatBehavior
    let pathType: PathType

    enum PathType: Sendable {
        case linear
        case curved
        case zigzag
    }

    enum RepeatBehavior: Sendable {
        case once
        case loop
        case pingPong  // Go forward then backward
    }

    init(
        waypoints: [FieldPosition],
        duration: TimeInterval = 3.0,
        repeatBehavior: RepeatBehavior = .loop,
        pathType: PathType = .linear
    ) {
        self.waypoints = waypoints
        self.duration = duration
        self.repeatBehavior = repeatBehavior
        self.pathType = pathType
    }

    // Create a simple back-and-forth path
    static func linear(from: FieldPosition, to: FieldPosition, duration: TimeInterval = 2.0) -> MovementPath {
        MovementPath(waypoints: [from, to], duration: duration, repeatBehavior: .pingPong, pathType: .linear)
    }

    // Create a circular/loop path
    static func loop(points: [FieldPosition], duration: TimeInterval = 4.0) -> MovementPath {
        var waypoints = points
        if let first = points.first {
            waypoints.append(first) // Close the loop
        }
        return MovementPath(waypoints: waypoints, duration: duration, repeatBehavior: .loop, pathType: .curved)
    }

    // Create a zigzag path through cones
    static func zigzag(points: [FieldPosition], duration: TimeInterval = 3.0) -> MovementPath {
        MovementPath(waypoints: points, duration: duration, repeatBehavior: .pingPong, pathType: .zigzag)
    }
}

// MARK: - Field Element Types

enum PlayerRole: String, Sendable {
    case primary    // Main player performing drill (blue)
    case partner    // Training partner (green)
    case teammate   // Team member (cyan)
    case defender   // Opposing player (red)
    case goalkeeper // Goalkeeper (yellow)

    var color: Color {
        switch self {
        case .primary: return .blue
        case .partner: return .green
        case .teammate: return .cyan
        case .defender: return .red
        case .goalkeeper: return .yellow
        }
    }
}

enum GoalSize: Sendable {
    case full
    case mini
}

enum FieldElementType: Equatable, Sendable {
    case player(role: PlayerRole)
    case ball
    case cone
    case goal(size: GoalSize)
    case ladder
    case hurdle
    case mannequin
    case pole
    case rebounder
    case wall

    static func == (lhs: FieldElementType, rhs: FieldElementType) -> Bool {
        switch (lhs, rhs) {
        case (.player(let r1), .player(let r2)): return r1 == r2
        case (.ball, .ball): return true
        case (.cone, .cone): return true
        case (.goal(let s1), .goal(let s2)): return s1 == s2
        case (.ladder, .ladder): return true
        case (.hurdle, .hurdle): return true
        case (.mannequin, .mannequin): return true
        case (.pole, .pole): return true
        case (.rebounder, .rebounder): return true
        case (.wall, .wall): return true
        default: return false
        }
    }
}

// MARK: - Field Element

struct FieldElement: Identifiable, Sendable {
    let id = UUID()
    let type: FieldElementType
    var position: FieldPosition
    var movementPath: MovementPath?
    var rotation: Angle
    var scale: CGFloat

    init(
        type: FieldElementType,
        position: FieldPosition,
        movementPath: MovementPath? = nil,
        rotation: Angle = .zero,
        scale: CGFloat = 1.0
    ) {
        self.type = type
        self.position = position
        self.movementPath = movementPath
        self.rotation = rotation
        self.scale = scale
    }

    // Convenience initializers
    static func player(_ role: PlayerRole, at position: FieldPosition, path: MovementPath? = nil) -> FieldElement {
        FieldElement(type: .player(role: role), position: position, movementPath: path)
    }

    static func ball(at position: FieldPosition, path: MovementPath? = nil) -> FieldElement {
        FieldElement(type: .ball, position: position, movementPath: path)
    }

    static func cone(at position: FieldPosition) -> FieldElement {
        FieldElement(type: .cone, position: position)
    }

    static func goal(at position: FieldPosition, size: GoalSize = .full) -> FieldElement {
        FieldElement(type: .goal(size: size), position: position)
    }

    static func ladder(at position: FieldPosition, rotation: Angle = .zero) -> FieldElement {
        FieldElement(type: .ladder, position: position, rotation: rotation)
    }

    static func hurdle(at position: FieldPosition) -> FieldElement {
        FieldElement(type: .hurdle, position: position)
    }

    static func mannequin(at position: FieldPosition) -> FieldElement {
        FieldElement(type: .mannequin, position: position)
    }

    static func rebounder(at position: FieldPosition, rotation: Angle = .zero) -> FieldElement {
        FieldElement(type: .rebounder, position: position, rotation: rotation)
    }

    static func wall(at position: FieldPosition) -> FieldElement {
        FieldElement(type: .wall, position: position)
    }
}

// MARK: - Tactical Scene

struct TacticalScene: Identifiable, Sendable {
    let id = UUID()
    let elements: [FieldElement]
    let loopDuration: TimeInterval
    let description: String?
    let showHalfField: Bool

    init(
        elements: [FieldElement],
        loopDuration: TimeInterval = 4.0,
        description: String? = nil,
        showHalfField: Bool = false
    ) {
        self.elements = elements
        self.loopDuration = loopDuration
        self.description = description
        self.showHalfField = showHalfField
    }

    // Empty scene for fallback
    static let empty = TacticalScene(elements: [], loopDuration: 1.0)
}

// MARK: - Animation Speed

enum AnimationSpeed: Sendable {
    case slow       // Beginner - 1.5x duration
    case normal     // Intermediate - 1.0x duration
    case fast       // Advanced - 0.7x duration

    var multiplier: Double {
        switch self {
        case .slow: return 1.5
        case .normal: return 1.0
        case .fast: return 0.7
        }
    }

    init(from skillLevel: SkillLevel) {
        switch skillLevel {
        case .beginner: self = .slow
        case .intermediate: self = .normal
        case .advanced: self = .fast
        }
    }
}
