import Foundation
import SwiftUI

/// Handles animation calculations for tactical board elements
struct AnimationEngine {

    // MARK: - Position Calculation

    /// Calculate the current position of an element along its path
    static func currentPosition(
        for element: FieldElement,
        at time: TimeInterval,
        speed: AnimationSpeed = .normal
    ) -> FieldPosition {
        guard let path = element.movementPath else {
            return element.position
        }

        let adjustedDuration = path.duration * speed.multiplier
        return positionOnPath(path, at: time, duration: adjustedDuration)
    }

    /// Calculate position along a movement path at a given time
    static func positionOnPath(
        _ path: MovementPath,
        at time: TimeInterval,
        duration: TimeInterval
    ) -> FieldPosition {
        guard path.waypoints.count >= 2 else {
            return path.waypoints.first ?? .center
        }

        // Calculate normalized progress (0 to 1)
        let cycleTime = time.truncatingRemainder(dividingBy: duration)
        var progress = cycleTime / duration

        // Handle repeat behavior
        switch path.repeatBehavior {
        case .once:
            progress = min(time / duration, 1.0)
        case .loop:
            // Progress goes 0 -> 1 -> 0 -> 1 ...
            break
        case .pingPong:
            // Progress goes 0 -> 1 -> 0 -> 1 ...
            let fullCycle = time.truncatingRemainder(dividingBy: duration * 2)
            if fullCycle > duration {
                progress = 1.0 - ((fullCycle - duration) / duration)
            } else {
                progress = fullCycle / duration
            }
        }

        return interpolateAlongPath(path.waypoints, progress: progress, type: path.pathType)
    }

    // MARK: - Path Interpolation

    /// Interpolate position along waypoints
    private static func interpolateAlongPath(
        _ waypoints: [FieldPosition],
        progress: CGFloat,
        type: MovementPath.PathType
    ) -> FieldPosition {
        guard waypoints.count >= 2 else {
            return waypoints.first ?? .center
        }

        let segmentCount = waypoints.count - 1
        let totalProgress = progress * CGFloat(segmentCount)
        let segmentIndex = min(Int(totalProgress), segmentCount - 1)
        let segmentProgress = totalProgress - CGFloat(segmentIndex)

        let start = waypoints[segmentIndex]
        let end = waypoints[segmentIndex + 1]

        switch type {
        case .linear:
            return linearInterpolation(from: start, to: end, progress: segmentProgress)
        case .curved:
            return curvedInterpolation(from: start, to: end, progress: segmentProgress)
        case .zigzag:
            return zigzagInterpolation(from: start, to: end, progress: segmentProgress)
        }
    }

    /// Simple linear interpolation between two points
    private static func linearInterpolation(
        from start: FieldPosition,
        to end: FieldPosition,
        progress: CGFloat
    ) -> FieldPosition {
        start.interpolated(to: end, progress: progress)
    }

    /// Smooth curved interpolation using ease-in-out
    private static func curvedInterpolation(
        from start: FieldPosition,
        to end: FieldPosition,
        progress: CGFloat
    ) -> FieldPosition {
        // Smooth ease-in-out curve
        let smoothProgress = easeInOut(progress)
        return start.interpolated(to: end, progress: smoothProgress)
    }

    /// Zigzag interpolation with sharp direction changes
    private static func zigzagInterpolation(
        from start: FieldPosition,
        to end: FieldPosition,
        progress: CGFloat
    ) -> FieldPosition {
        // Quick acceleration at start, deceleration at end
        let sharpProgress = easeOutQuad(progress)
        return start.interpolated(to: end, progress: sharpProgress)
    }

    // MARK: - Easing Functions

    /// Smooth ease-in-out (sine curve)
    private static func easeInOut(_ t: CGFloat) -> CGFloat {
        -(cos(CGFloat.pi * t) - 1) / 2
    }

    /// Quick ease-out (quadratic)
    private static func easeOutQuad(_ t: CGFloat) -> CGFloat {
        1 - (1 - t) * (1 - t)
    }

    /// Ease-in (quadratic)
    private static func easeInQuad(_ t: CGFloat) -> CGFloat {
        t * t
    }

    // MARK: - Ball Movement

    /// Calculate ball position following a player or on its own path
    static func ballPosition(
        following playerPosition: FieldPosition,
        offset: CGFloat = 0.03
    ) -> FieldPosition {
        // Ball stays slightly in front of player
        FieldPosition(
            x: playerPosition.x,
            y: playerPosition.y + offset
        )
    }

    /// Calculate ball position for a pass
    static func ballPassPosition(
        from start: FieldPosition,
        to end: FieldPosition,
        progress: CGFloat
    ) -> FieldPosition {
        // Ball moves faster than players with slight arc
        let fastProgress = easeOutQuad(progress)
        let basePosition = start.interpolated(to: end, progress: fastProgress)

        // Add slight vertical arc for realism
        let arcHeight: CGFloat = 0.02
        let arcProgress = sin(progress * CGFloat.pi) * arcHeight

        return FieldPosition(
            x: basePosition.x,
            y: basePosition.y - arcProgress
        )
    }

    // MARK: - Direction Calculation

    /// Calculate the direction angle an element should face
    static func direction(
        for element: FieldElement,
        at time: TimeInterval,
        speed: AnimationSpeed = .normal
    ) -> Angle {
        guard let path = element.movementPath, path.waypoints.count >= 2 else {
            return element.rotation
        }

        let adjustedDuration = path.duration * speed.multiplier

        // Get current and next positions to determine direction
        let currentPos = positionOnPath(path, at: time, duration: adjustedDuration)
        let nextPos = positionOnPath(path, at: time + 0.05, duration: adjustedDuration)

        let angle = currentPos.angle(to: nextPos)
        return Angle(radians: angle)
    }

    // MARK: - Scene Animation

    /// Get all animated element positions for a scene at a given time
    static func animatedElements(
        for scene: TacticalScene,
        at time: TimeInterval,
        speed: AnimationSpeed = .normal
    ) -> [(element: FieldElement, position: FieldPosition, direction: Angle)] {
        let loopTime = time.truncatingRemainder(dividingBy: scene.loopDuration * speed.multiplier)

        return scene.elements.map { element in
            let position = currentPosition(for: element, at: loopTime, speed: speed)
            let direction = direction(for: element, at: loopTime, speed: speed)
            return (element, position, direction)
        }
    }
}
