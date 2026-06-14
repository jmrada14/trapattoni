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

        let progress = pathProgress(at: time, duration: duration, repeatBehavior: path.repeatBehavior)
        return interpolateAlongPath(path, progress: progress)
    }

    /// Normalized progress (0 to 1) along a path for a given time.
    /// PingPong paths ease in and out so direction changes look like a
    /// player decelerating, turning, and accelerating again.
    private static func pathProgress(
        at time: TimeInterval,
        duration: TimeInterval,
        repeatBehavior: MovementPath.RepeatBehavior
    ) -> CGFloat {
        guard duration > 0 else { return 0 }

        switch repeatBehavior {
        case .once:
            return CGFloat(min(max(time / duration, 0), 1))
        case .loop:
            let cycleTime = time.truncatingRemainder(dividingBy: duration)
            return CGFloat(cycleTime < 0 ? cycleTime + duration : cycleTime) / CGFloat(duration)
        case .pingPong:
            var cycle = time.truncatingRemainder(dividingBy: duration * 2)
            if cycle < 0 { cycle += duration * 2 }
            let leg = cycle < duration
                ? cycle / duration
                : 1.0 - (cycle - duration) / duration
            return easeInOut(CGFloat(leg))
        }
    }

    // MARK: - Path Interpolation

    /// Interpolate position along a path at normalized progress (0 to 1).
    /// Progress maps to distance travelled (arc length), so elements move at
    /// constant speed regardless of how waypoints are spaced.
    static func interpolateAlongPath(
        _ path: MovementPath,
        progress: CGFloat
    ) -> FieldPosition {
        let waypoints = path.waypoints
        guard waypoints.count >= 2, path.totalLength > 0 else {
            return waypoints.first ?? .center
        }

        let targetDistance = min(max(progress, 0), 1) * path.totalLength

        var travelled: CGFloat = 0
        var segmentIndex = path.segmentLengths.count - 1
        for (i, length) in path.segmentLengths.enumerated() {
            if travelled + length >= targetDistance {
                segmentIndex = i
                break
            }
            travelled += length
        }

        let segmentLength = max(path.segmentLengths[segmentIndex], 0.000001)
        let t = min(max((targetDistance - travelled) / segmentLength, 0), 1)

        switch path.pathType {
        case .linear:
            return waypoints[segmentIndex].interpolated(to: waypoints[segmentIndex + 1], progress: t)
        case .curved:
            let (p0, p1, p2, p3) = controlPoints(for: segmentIndex, in: path)
            return catmullRomPoint(p0, p1, p2, p3, t: t)
        }
    }

    /// Sampled points along a path, for drawing trails that match the actual
    /// motion (curved paths return spline samples, not just waypoints).
    static func trailPoints(for path: MovementPath, samplesPerSegment: Int = 10) -> [FieldPosition] {
        let waypoints = path.waypoints
        guard waypoints.count >= 2 else { return waypoints }

        switch path.pathType {
        case .linear:
            return waypoints
        case .curved:
            var points: [FieldPosition] = []
            for segmentIndex in 0..<(waypoints.count - 1) {
                let (p0, p1, p2, p3) = controlPoints(for: segmentIndex, in: path)
                for sample in 0..<samplesPerSegment {
                    let t = CGFloat(sample) / CGFloat(samplesPerSegment)
                    points.append(catmullRomPoint(p0, p1, p2, p3, t: t))
                }
            }
            if let last = waypoints.last {
                points.append(last)
            }
            return points
        }
    }

    // MARK: - Catmull-Rom Spline

    /// Control points for the spline segment between waypoint i and i+1.
    /// Closed loops wrap around for a seamless curve; open paths clamp ends.
    private static func controlPoints(
        for segmentIndex: Int,
        in path: MovementPath
    ) -> (FieldPosition, FieldPosition, FieldPosition, FieldPosition) {
        let waypoints = path.waypoints
        let p1 = waypoints[segmentIndex]
        let p2 = waypoints[segmentIndex + 1]

        let p0: FieldPosition
        let p3: FieldPosition

        if path.isClosed {
            // Unique points exclude the duplicated closing waypoint
            let count = waypoints.count - 1
            p0 = waypoints[(segmentIndex - 1 + count) % count]
            p3 = waypoints[(segmentIndex + 2) % count]
        } else {
            p0 = segmentIndex > 0 ? waypoints[segmentIndex - 1] : p1
            p3 = segmentIndex + 2 < waypoints.count ? waypoints[segmentIndex + 2] : p2
        }

        return (p0, p1, p2, p3)
    }

    /// Centripetal Catmull-Rom interpolation (Barry-Goldman formulation).
    /// Passes through p1 and p2; centripetal knots avoid loops and overshoot.
    private static func catmullRomPoint(
        _ p0: FieldPosition,
        _ p1: FieldPosition,
        _ p2: FieldPosition,
        _ p3: FieldPosition,
        t: CGFloat
    ) -> FieldPosition {
        func knotInterval(_ a: FieldPosition, _ b: FieldPosition) -> CGFloat {
            max(sqrt(a.distance(to: b)), 0.0001)
        }

        let t0: CGFloat = 0
        let t1 = t0 + knotInterval(p0, p1)
        let t2 = t1 + knotInterval(p1, p2)
        let t3 = t2 + knotInterval(p2, p3)
        let u = t1 + (t2 - t1) * t

        func blend(_ a: FieldPosition, _ b: FieldPosition, _ ta: CGFloat, _ tb: CGFloat) -> FieldPosition {
            a.interpolated(to: b, progress: (u - ta) / (tb - ta))
        }

        let a1 = blend(p0, p1, t0, t1)
        let a2 = blend(p1, p2, t1, t2)
        let a3 = blend(p2, p3, t2, t3)
        let b1 = blend(a1, a2, t0, t2)
        let b2 = blend(a2, a3, t1, t3)
        return blend(b1, b2, t1, t2)
    }

    // MARK: - Easing Functions

    /// Smooth ease-in-out (sine curve)
    private static func easeInOut(_ t: CGFloat) -> CGFloat {
        -(cos(CGFloat.pi * t) - 1) / 2
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
        let lookAhead = 0.03

        let currentPos = positionOnPath(path, at: time, duration: adjustedDuration)
        let nextPos = positionOnPath(path, at: time + lookAhead, duration: adjustedDuration)
        let stepDistance = currentPos.distance(to: nextPos)

        // A huge step means the loop wrapped around (teleport frame);
        // look backward instead so the element doesn't flip for one frame.
        if stepDistance > 0.2 {
            let previousPos = positionOnPath(path, at: time - lookAhead, duration: adjustedDuration)
            return Angle(radians: previousPos.angle(to: currentPos))
        }

        // Effectively stationary (e.g. pingPong turnaround) - keep base rotation
        if stepDistance < 0.00001 {
            return element.rotation
        }

        return Angle(radians: currentPos.angle(to: nextPos))
    }
}
