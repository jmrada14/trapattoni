import Foundation
import SwiftUI

/// Builds unique tactical scenes for each specific exercise
struct ExerciseAnimationBuilder {

    // MARK: - Main Builder

    static func buildScene(for exercise: Exercise) -> TacticalScene {
        // Look up by exact exercise name
        switch exercise.name {
        // MARK: - Dribbling Exercises
        case "Cone Weave Dribbling":
            return coneWeaveDribbling()
        case "Speed Dribble Sprints":
            return speedDribbleSprints()
        case "Figure 8 Dribbling":
            return figure8Dribbling()
        case "La Croqueta":
            return laCroqueta()
        case "1v1 Dribbling Battles":
            return oneVOneDribblingBattles()
        case "Shadow Dribbling":
            return shadowDribbling()
        case "Dribbling Relay Race":
            return dribblingRelayRace()
        case "Keep Ball (Rondo)":
            return keepBallRondo()

        // MARK: - Passing Exercises
        case "Wall Passing Repetitions":
            return wallPassingRepetitions()
        case "Rebounder Passing":
            return rebounderPassing()
        case "Partner Passing Sequence":
            return partnerPassingSequence()
        case "Triangle Passing":
            return trianglePassing()
        case "Give and Go (Wall Pass)":
            return giveAndGo()
        case "Long Ball Practice":
            return longBallPractice()
        case "One-Touch Passing Squares":
            return oneTouchPassingSquares()
        case "Possession Grid":
            return possessionGrid()

        // MARK: - Shooting Exercises
        case "Finesse Shooting":
            return finesseShooting()
        case "Power Shots":
            return powerShots()
        case "Volley Practice":
            return volleyPractice()
        case "Shooting Under Pressure":
            return shootingUnderPressure()
        case "Crossing and Finishing":
            return crossingAndFinishing()
        case "Shooting Circuit":
            return shootingCircuit()
        case "Small-Sided Finishing Game":
            return smallSidedFinishingGame()

        // MARK: - First Touch Exercises
        case "Cushion Control":
            return cushionControl()
        case "Trap and Turn":
            return trapAndTurn()
        case "Aerial Control":
            return aerialControl()
        case "First Touch Under Pressure":
            return firstTouchUnderPressure()
        case "Control and Combine":
            return controlAndCombine()

        // MARK: - Fitness Exercises
        case "Ladder Agility Drills":
            return ladderAgilityDrills()
        case "Shuttle Runs":
            return shuttleRuns()
        case "Box Jumps":
            return boxJumps()
        case "Sprint Recovery Intervals":
            return sprintRecoveryIntervals()
        case "Partner Sprint Races":
            return partnerSprintRaces()
        case "Resistance Band Partner Runs":
            return resistanceBandRuns()
        case "Team Fitness Circuit":
            return teamFitnessCircuit()

        // MARK: - Goalkeeping Exercises
        case "Diving Save Practice":
            return divingSavePractice()
        case "Distribution Practice":
            return distributionPractice()
        case "Shot Stopping Reactions":
            return shotStoppingReactions()
        case "Goalkeeper Communication Drill":
            return goalkeeperCommunication()

        // MARK: - Defending Exercises
        case "1v1 Defending":
            return oneVOneDefending()
        case "Defensive Positioning":
            return defensivePositioning()
        case "Clearance Practice":
            return clearancePractice()
        case "2v2 Defending":
            return twoVTwoDefending()
        case "Pressing Triggers":
            return pressingTriggers()

        // MARK: - Set Pieces Exercises
        case "Free Kick Technique":
            return freeKickTechnique()
        case "Corner Delivery":
            return cornerDelivery()
        case "Penalty Practice":
            return penaltyPractice()
        case "Throw-In Routines":
            return throwInRoutines()
        case "Set Piece Attacking Routines":
            return setPieceAttackingRoutines()
        case "Defensive Set Piece Organization":
            return defensiveSetPieceOrganization()

        default:
            return fallbackScene(for: exercise)
        }
    }

    // MARK: - Fallback for unknown exercises

    private static func fallbackScene(for exercise: Exercise) -> TacticalScene {
        var elements: [FieldElement] = []
        elements.append(.player(.primary, at: FieldPosition(x: 0.5, y: 0.5)))
        elements.append(.ball(at: FieldPosition(x: 0.5, y: 0.55)))
        return TacticalScene(elements: elements, loopDuration: 3.0)
    }
}

// MARK: - Dribbling Exercises

extension ExerciseAnimationBuilder {

    /// Cone Weave Dribbling: 8-10 cones in a line, player weaves through them
    private static func coneWeaveDribbling() -> TacticalScene {
        var elements: [FieldElement] = []

        // 8 cones in a vertical line down the center
        let coneCount = 8
        let startY: CGFloat = 0.85
        let spacing: CGFloat = 0.085

        for i in 0..<coneCount {
            let y = startY - CGFloat(i) * spacing
            elements.append(.cone(at: FieldPosition(x: 0.5, y: y)))
        }

        // Player weaves left-right through cones
        var waypoints: [FieldPosition] = []
        for i in 0..<coneCount {
            let y = startY - CGFloat(i) * spacing
            let offsetX: CGFloat = (i % 2 == 0) ? -0.08 : 0.08
            waypoints.append(FieldPosition(x: 0.5 + offsetX, y: y + 0.02))
        }
        waypoints.append(FieldPosition(x: 0.5, y: startY - CGFloat(coneCount) * spacing))

        let playerPath = MovementPath(
            waypoints: waypoints,
            duration: 4.0,
            repeatBehavior: .pingPong,
            pathType: .curved
        )
        elements.append(.player(.primary, at: waypoints[0], path: playerPath))

        // Ball follows player closely
        let ballWaypoints = waypoints.map { FieldPosition(x: $0.x, y: $0.y + 0.025) }
        let ballPath = MovementPath(
            waypoints: ballWaypoints,
            duration: 4.0,
            repeatBehavior: .pingPong,
            pathType: .curved
        )
        elements.append(.ball(at: ballWaypoints[0], path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }

    /// Speed Dribble Sprints: 30m sprint pushing ball ahead
    private static func speedDribbleSprints() -> TacticalScene {
        var elements: [FieldElement] = []

        // Start and end cones
        elements.append(.cone(at: FieldPosition(x: 0.5, y: 0.88)))
        elements.append(.cone(at: FieldPosition(x: 0.5, y: 0.12)))

        // Player sprints from bottom to top
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.5, y: 0.85),
                FieldPosition(x: 0.5, y: 0.15)
            ],
            duration: 2.5,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.5, y: 0.85), path: playerPath))

        // Ball pushed ahead of player (2-3m ahead)
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.5, y: 0.75),  // Ball starts ahead
                FieldPosition(x: 0.5, y: 0.12)   // Ball reaches end first
            ],
            duration: 2.5,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.5, y: 0.75), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 2.5)
    }

    /// Figure 8 Dribbling: Two cones, player dribbles in figure-8 pattern
    private static func figure8Dribbling() -> TacticalScene {
        var elements: [FieldElement] = []

        // Two cones placed horizontally
        let leftCone = FieldPosition(x: 0.35, y: 0.5)
        let rightCone = FieldPosition(x: 0.65, y: 0.5)
        elements.append(.cone(at: leftCone))
        elements.append(.cone(at: rightCone))

        // Figure-8 path around the two cones
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.5, y: 0.5),    // Center start
                FieldPosition(x: 0.35, y: 0.38),  // Around left cone (top)
                FieldPosition(x: 0.22, y: 0.5),   // Left side
                FieldPosition(x: 0.35, y: 0.62),  // Around left cone (bottom)
                FieldPosition(x: 0.5, y: 0.5),    // Center
                FieldPosition(x: 0.65, y: 0.62),  // Around right cone (bottom)
                FieldPosition(x: 0.78, y: 0.5),   // Right side
                FieldPosition(x: 0.65, y: 0.38),  // Around right cone (top)
                FieldPosition(x: 0.5, y: 0.5)     // Back to center
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.5, y: 0.5), path: playerPath))

        // Ball follows player
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.5, y: 0.53),
                FieldPosition(x: 0.35, y: 0.41),
                FieldPosition(x: 0.22, y: 0.53),
                FieldPosition(x: 0.35, y: 0.65),
                FieldPosition(x: 0.5, y: 0.53),
                FieldPosition(x: 0.65, y: 0.65),
                FieldPosition(x: 0.78, y: 0.53),
                FieldPosition(x: 0.65, y: 0.41),
                FieldPosition(x: 0.5, y: 0.53)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.5, y: 0.53), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 5.0)
    }

    /// La Croqueta: Quick side-to-side ball shifts between feet
    private static func laCroqueta() -> TacticalScene {
        var elements: [FieldElement] = []

        // Player stays relatively stationary with subtle weight shifts
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.48, y: 0.5),
                FieldPosition(x: 0.52, y: 0.5),
                FieldPosition(x: 0.48, y: 0.5)
            ],
            duration: 0.8,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.5, y: 0.5), path: playerPath))

        // Ball shifts rapidly left-right between feet
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.42, y: 0.55),  // Left foot
                FieldPosition(x: 0.58, y: 0.55),  // Right foot
                FieldPosition(x: 0.42, y: 0.55)   // Back to left
            ],
            duration: 0.8,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.42, y: 0.55), path: ballPath))

        // Mannequin as imaginary defender
        elements.append(.mannequin(at: FieldPosition(x: 0.5, y: 0.35)))

        return TacticalScene(elements: elements, loopDuration: 0.8)
    }

    /// 1v1 Dribbling Battles: Attacker vs defender in small grid
    private static func oneVOneDribblingBattles() -> TacticalScene {
        var elements: [FieldElement] = []

        // Grid corners
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.75)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.75)))

        // Target line at top
        elements.append(.cone(at: FieldPosition(x: 0.40, y: 0.20)))
        elements.append(.cone(at: FieldPosition(x: 0.60, y: 0.20)))

        // Attacker tries to beat defender
        let attackerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.70),
                FieldPosition(x: 0.40, y: 0.55),  // Feint left
                FieldPosition(x: 0.55, y: 0.45),  // Cut right
                FieldPosition(x: 0.50, y: 0.30),  // Beat defender!
                FieldPosition(x: 0.50, y: 0.70)   // Reset
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.70), path: attackerPath))

        // Ball with attacker
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.73),
                FieldPosition(x: 0.40, y: 0.58),
                FieldPosition(x: 0.55, y: 0.48),
                FieldPosition(x: 0.50, y: 0.33),
                FieldPosition(x: 0.50, y: 0.73)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.73), path: ballPath))

        // Defender trying to stop attacker
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.45),
                FieldPosition(x: 0.42, y: 0.48),  // Reacts to feint
                FieldPosition(x: 0.52, y: 0.42),  // Gets beaten
                FieldPosition(x: 0.50, y: 0.38),
                FieldPosition(x: 0.50, y: 0.45)   // Reset
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.45), path: defenderPath))

        return TacticalScene(elements: elements, loopDuration: 4.5)
    }

    /// Shadow Dribbling: Leader with ball, follower mirrors without ball
    private static func shadowDribbling() -> TacticalScene {
        var elements: [FieldElement] = []

        // Leader with ball moves unpredictably
        let leaderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.35, y: 0.40),
                FieldPosition(x: 0.60, y: 0.55),
                FieldPosition(x: 0.45, y: 0.65),
                FieldPosition(x: 0.65, y: 0.45),
                FieldPosition(x: 0.50, y: 0.50)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: leaderPath))

        // Ball with leader
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.53),
                FieldPosition(x: 0.35, y: 0.43),
                FieldPosition(x: 0.60, y: 0.58),
                FieldPosition(x: 0.45, y: 0.68),
                FieldPosition(x: 0.65, y: 0.48),
                FieldPosition(x: 0.50, y: 0.53)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.53), path: ballPath))

        // Follower mirrors 2m behind (no ball)
        let followerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.58),
                FieldPosition(x: 0.35, y: 0.48),
                FieldPosition(x: 0.60, y: 0.63),
                FieldPosition(x: 0.45, y: 0.73),
                FieldPosition(x: 0.65, y: 0.53),
                FieldPosition(x: 0.50, y: 0.58)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.58), path: followerPath))

        return TacticalScene(elements: elements, loopDuration: 5.0)
    }

    /// Dribbling Relay Race: Teams dribble through cones
    private static func dribblingRelayRace() -> TacticalScene {
        var elements: [FieldElement] = []

        // Cones for slalom course (two lanes)
        for i in 0..<4 {
            let y = 0.75 - CGFloat(i) * 0.15
            elements.append(.cone(at: FieldPosition(x: 0.30, y: y)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: y)))
        }

        // Start/finish line
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.85)))

        // Player 1 (left lane) racing
        let player1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.82),
                FieldPosition(x: 0.25, y: 0.70),
                FieldPosition(x: 0.35, y: 0.55),
                FieldPosition(x: 0.25, y: 0.40),
                FieldPosition(x: 0.30, y: 0.28),
                FieldPosition(x: 0.30, y: 0.82)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.82), path: player1Path))

        // Ball with player 1
        let ball1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.85),
                FieldPosition(x: 0.25, y: 0.73),
                FieldPosition(x: 0.35, y: 0.58),
                FieldPosition(x: 0.25, y: 0.43),
                FieldPosition(x: 0.30, y: 0.31),
                FieldPosition(x: 0.30, y: 0.85)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.30, y: 0.85), path: ball1Path))

        // Player 2 (right lane) racing - slightly offset timing
        let player2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.70, y: 0.55),
                FieldPosition(x: 0.75, y: 0.40),
                FieldPosition(x: 0.65, y: 0.28),
                FieldPosition(x: 0.70, y: 0.82),
                FieldPosition(x: 0.65, y: 0.70),
                FieldPosition(x: 0.70, y: 0.55)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.70, y: 0.55), path: player2Path))

        // Waiting teammates
        elements.append(.player(.teammate, at: FieldPosition(x: 0.20, y: 0.90)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.80, y: 0.90)))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }

    /// Keep Ball (Rondo): Players in circle, defender in middle
    private static func keepBallRondo() -> TacticalScene {
        var elements: [FieldElement] = []

        let centerX: CGFloat = 0.5
        let centerY: CGFloat = 0.5
        let radius: CGFloat = 0.25

        // 5 players in a circle
        for i in 0..<5 {
            let angle = CGFloat(i) * (2 * .pi / 5) - .pi / 2
            let x = centerX + cos(angle) * radius
            let y = centerY + sin(angle) * radius
            let role: PlayerRole = i == 0 ? .primary : .teammate
            elements.append(.player(role, at: FieldPosition(x: x, y: y)))
        }

        // Defender in the middle chasing ball
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.55, y: 0.45),
                FieldPosition(x: 0.48, y: 0.52),
                FieldPosition(x: 0.52, y: 0.55),
                FieldPosition(x: 0.50, y: 0.50)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.50), path: defenderPath))

        // Ball circulating around the circle (passing player to player)
        var ballWaypoints: [FieldPosition] = []
        for i in 0...5 {
            let angle = CGFloat(i % 5) * (2 * .pi / 5) - .pi / 2
            let x = centerX + cos(angle) * (radius * 0.85)
            let y = centerY + sin(angle) * (radius * 0.85)
            ballWaypoints.append(FieldPosition(x: x, y: y))
        }
        let ballPath = MovementPath(
            waypoints: ballWaypoints,
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: ballWaypoints[0], path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }
}

// MARK: - Passing Exercises

extension ExerciseAnimationBuilder {

    /// Wall Passing Repetitions: Player passing against a wall
    private static func wallPassingRepetitions() -> TacticalScene {
        var elements: [FieldElement] = []

        // Wall at the top
        elements.append(.wall(at: FieldPosition(x: 0.5, y: 0.20)))

        // Player moves slightly side to side while passing
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.55),
                FieldPosition(x: 0.50, y: 0.53),
                FieldPosition(x: 0.55, y: 0.55),
                FieldPosition(x: 0.50, y: 0.53),
                FieldPosition(x: 0.45, y: 0.55)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.45, y: 0.55), path: playerPath))

        // Ball goes to wall and rebounds back
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.50),  // At player
                FieldPosition(x: 0.47, y: 0.24),  // Hits wall
                FieldPosition(x: 0.50, y: 0.48),  // Returns
                FieldPosition(x: 0.52, y: 0.24),  // Hits wall
                FieldPosition(x: 0.55, y: 0.50),  // Returns
                FieldPosition(x: 0.52, y: 0.24),  // Hits wall
                FieldPosition(x: 0.50, y: 0.48),  // Returns
                FieldPosition(x: 0.47, y: 0.24),  // Hits wall
                FieldPosition(x: 0.45, y: 0.50)   // Back to start
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.45, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.0)
    }

    /// Rebounder Passing: Using angled rebounder for unpredictable returns
    private static func rebounderPassing() -> TacticalScene {
        var elements: [FieldElement] = []

        // Rebounder (angled)
        elements.append(.rebounder(at: FieldPosition(x: 0.5, y: 0.25), rotation: .degrees(10)))

        // Player adjusting to receive at different angles
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.55),
                FieldPosition(x: 0.48, y: 0.52),
                FieldPosition(x: 0.55, y: 0.58),
                FieldPosition(x: 0.52, y: 0.55),
                FieldPosition(x: 0.45, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.45, y: 0.55), path: playerPath))

        // Ball with unpredictable angles
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.52),  // From player
                FieldPosition(x: 0.48, y: 0.28),  // Hit rebounder
                FieldPosition(x: 0.52, y: 0.50),  // Returns at angle
                FieldPosition(x: 0.55, y: 0.28),  // Hit rebounder
                FieldPosition(x: 0.48, y: 0.55),  // Returns at angle
                FieldPosition(x: 0.45, y: 0.28),  // Hit rebounder
                FieldPosition(x: 0.45, y: 0.52)   // Returns
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.45, y: 0.52), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }

    /// Partner Passing Sequence: Two players 10-15m apart passing back and forth
    private static func partnerPassingSequence() -> TacticalScene {
        var elements: [FieldElement] = []

        // Distance markers
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.45)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.45)))
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.55)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.55)))

        // Player 1 (left) - slight movement when passing/receiving
        let player1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.25, y: 0.50),
                FieldPosition(x: 0.27, y: 0.48),
                FieldPosition(x: 0.25, y: 0.50),
                FieldPosition(x: 0.27, y: 0.52),
                FieldPosition(x: 0.25, y: 0.50)
            ],
            duration: 2.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.25, y: 0.50), path: player1Path))

        // Player 2 (right)
        let player2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.75, y: 0.50),
                FieldPosition(x: 0.73, y: 0.52),
                FieldPosition(x: 0.75, y: 0.50),
                FieldPosition(x: 0.73, y: 0.48),
                FieldPosition(x: 0.75, y: 0.50)
            ],
            duration: 2.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.75, y: 0.50), path: player2Path))

        // Ball passing between them
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.28, y: 0.50),
                FieldPosition(x: 0.72, y: 0.50)
            ],
            duration: 1.25,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 2.5)
    }

    /// Triangle Passing: 3 players pass and follow their pass
    private static func trianglePassing() -> TacticalScene {
        var elements: [FieldElement] = []

        // Three cone positions
        let p1 = FieldPosition(x: 0.50, y: 0.25)  // Top
        let p2 = FieldPosition(x: 0.25, y: 0.70)  // Bottom left
        let p3 = FieldPosition(x: 0.75, y: 0.70)  // Bottom right

        elements.append(.cone(at: p1))
        elements.append(.cone(at: p2))
        elements.append(.cone(at: p3))

        // Player 1 moves: top -> bottom left -> bottom right -> top
        let player1Path = MovementPath(
            waypoints: [p1, p2, p3, p1],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.primary, at: p1, path: player1Path))

        // Player 2 moves: bottom left -> bottom right -> top -> bottom left
        let player2Path = MovementPath(
            waypoints: [p2, p3, p1, p2],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: p2, path: player2Path))

        // Player 3 moves: bottom right -> top -> bottom left -> bottom right
        let player3Path = MovementPath(
            waypoints: [p3, p1, p2, p3],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: p3, path: player3Path))

        // Ball circulates slightly ahead of player movement
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.48, y: 0.30),
                FieldPosition(x: 0.28, y: 0.67),
                FieldPosition(x: 0.72, y: 0.67),
                FieldPosition(x: 0.48, y: 0.30)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.48, y: 0.30), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.5)
    }

    /// Give and Go (Wall Pass): Player passes, sprints past defender, receives return
    private static func giveAndGo() -> TacticalScene {
        var elements: [FieldElement] = []

        // Mannequin as defender to run past
        elements.append(.mannequin(at: FieldPosition(x: 0.50, y: 0.50)))

        // Player A - passes, sprints, receives
        let playerAPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.40, y: 0.70),  // Start with ball
                FieldPosition(x: 0.42, y: 0.65),  // Pass moment
                FieldPosition(x: 0.55, y: 0.45),  // Sprint past defender
                FieldPosition(x: 0.55, y: 0.35),  // Receive return pass
                FieldPosition(x: 0.40, y: 0.70)   // Reset
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.40, y: 0.70), path: playerAPath))

        // Player B - receives first pass, plays return
        let playerBPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.60, y: 0.60),
                FieldPosition(x: 0.58, y: 0.58),
                FieldPosition(x: 0.60, y: 0.55),
                FieldPosition(x: 0.60, y: 0.60)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.60, y: 0.60), path: playerBPath))

        // Ball - pass to B, return to A in space
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.42, y: 0.68),  // At A
                FieldPosition(x: 0.58, y: 0.58),  // To B
                FieldPosition(x: 0.55, y: 0.38),  // Return pass in front of A
                FieldPosition(x: 0.42, y: 0.68)   // Reset
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.42, y: 0.68), path: ballPath))

        // Cones marking the run
        elements.append(.cone(at: FieldPosition(x: 0.40, y: 0.72)))
        elements.append(.cone(at: FieldPosition(x: 0.55, y: 0.32)))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }

    /// Long Ball Practice: 30m+ passes between players
    private static func longBallPractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Target cones at each end
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.12)))
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.88)))

        // Player 1 at bottom
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.85)))

        // Player 2 at top
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.15)))

        // Ball - lofted flight between players (with arc effect via waypoints)
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.82),  // Kicked from bottom
                FieldPosition(x: 0.50, y: 0.50),  // Peak of flight (higher up = middle)
                FieldPosition(x: 0.50, y: 0.18),  // Lands at top
                FieldPosition(x: 0.50, y: 0.50),  // Peak of return
                FieldPosition(x: 0.50, y: 0.82)   // Back at bottom
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.82), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }

    /// One-Touch Passing Squares: 4 players on corners passing in sequence
    private static func oneTouchPassingSquares() -> TacticalScene {
        var elements: [FieldElement] = []

        // Four corners of square
        let tl = FieldPosition(x: 0.30, y: 0.30)
        let tr = FieldPosition(x: 0.70, y: 0.30)
        let br = FieldPosition(x: 0.70, y: 0.70)
        let bl = FieldPosition(x: 0.30, y: 0.70)

        elements.append(.cone(at: tl))
        elements.append(.cone(at: tr))
        elements.append(.cone(at: br))
        elements.append(.cone(at: bl))

        // Four players at corners
        elements.append(.player(.primary, at: tl))
        elements.append(.player(.partner, at: tr))
        elements.append(.player(.teammate, at: br))
        elements.append(.player(.teammate, at: bl))

        // Ball moves around the square one-touch
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.33, y: 0.33),
                FieldPosition(x: 0.67, y: 0.33),
                FieldPosition(x: 0.67, y: 0.67),
                FieldPosition(x: 0.33, y: 0.67),
                FieldPosition(x: 0.33, y: 0.33)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.33, y: 0.33), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.0)
    }

    /// Possession Grid: Two teams keeping the ball in a grid
    private static func possessionGrid() -> TacticalScene {
        var elements: [FieldElement] = []

        // Grid corners
        elements.append(.cone(at: FieldPosition(x: 0.20, y: 0.20)))
        elements.append(.cone(at: FieldPosition(x: 0.80, y: 0.20)))
        elements.append(.cone(at: FieldPosition(x: 0.20, y: 0.80)))
        elements.append(.cone(at: FieldPosition(x: 0.80, y: 0.80)))

        // Team in possession (blue) - 4 players
        elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.40)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.70, y: 0.35)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.55, y: 0.65)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.35, y: 0.70)))

        // Pressing team (red) - 2 defenders
        let def1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.50),
                FieldPosition(x: 0.55, y: 0.45),
                FieldPosition(x: 0.50, y: 0.55),
                FieldPosition(x: 0.45, y: 0.50)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.45, y: 0.50), path: def1Path))
        elements.append(.player(.defender, at: FieldPosition(x: 0.55, y: 0.55)))

        // Ball moving between possession team
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.33, y: 0.42),
                FieldPosition(x: 0.67, y: 0.38),
                FieldPosition(x: 0.55, y: 0.62),
                FieldPosition(x: 0.38, y: 0.68),
                FieldPosition(x: 0.33, y: 0.42)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.33, y: 0.42), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }
}

// MARK: - Shooting Exercises

extension ExerciseAnimationBuilder {

    /// Finesse Shooting: Curling shots from edge of box
    private static func finesseShooting() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.18),
                FieldPosition(x: 0.55, y: 0.17),  // Dive attempt
                FieldPosition(x: 0.50, y: 0.18)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18), path: gkPath))

        // Shooter approaching from edge of box
        let shooterPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.55),
                FieldPosition(x: 0.38, y: 0.45),
                FieldPosition(x: 0.42, y: 0.38),  // Strike position
                FieldPosition(x: 0.42, y: 0.38),  // Pause for shot
                FieldPosition(x: 0.30, y: 0.55)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.55), path: shooterPath))

        // Ball - curving shot into far corner
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.58),
                FieldPosition(x: 0.38, y: 0.48),
                FieldPosition(x: 0.42, y: 0.40),  // At feet
                FieldPosition(x: 0.55, y: 0.25),  // Curving
                FieldPosition(x: 0.62, y: 0.10),  // Into far corner!
                FieldPosition(x: 0.30, y: 0.58)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.30, y: 0.58), path: ballPath))

        // Cone marking shooting zone
        elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.35)))
        elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.35)))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Power Shots: Striking with laces for maximum power
    private static func powerShots() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.18),
                FieldPosition(x: 0.48, y: 0.17),
                FieldPosition(x: 0.50, y: 0.18)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18), path: gkPath))

        // Shooter running up to ball
        let shooterPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.65),  // Start
                FieldPosition(x: 0.50, y: 0.55),  // Approach
                FieldPosition(x: 0.50, y: 0.48),  // Strike!
                FieldPosition(x: 0.50, y: 0.48),  // Follow through
                FieldPosition(x: 0.50, y: 0.65)   // Reset
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.65), path: shooterPath))

        // Ball - powerful straight shot
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),  // On ground
                FieldPosition(x: 0.50, y: 0.50),  // Pause
                FieldPosition(x: 0.50, y: 0.10),  // Rockets into goal!
                FieldPosition(x: 0.50, y: 0.50)   // Reset
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.5, showHalfField: true)
    }

    /// Volley Practice: Striking balls out of the air
    private static func volleyPractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18)))

        // Player preparing to volley
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.45),
                FieldPosition(x: 0.52, y: 0.43),  // Adjust position
                FieldPosition(x: 0.50, y: 0.42),  // Strike volley
                FieldPosition(x: 0.50, y: 0.45)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.45), path: playerPath))

        // Ball tossed up and volleyed (arc pattern)
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.48),  // Self-toss start
                FieldPosition(x: 0.50, y: 0.35),  // Ball in air (peak)
                FieldPosition(x: 0.50, y: 0.42),  // Dropping
                FieldPosition(x: 0.50, y: 0.10),  // Volleyed into goal!
                FieldPosition(x: 0.50, y: 0.48)   // Reset
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.48), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.0, showHalfField: true)
    }

    /// Shooting Under Pressure: Quick shots with defender closing
    private static func shootingUnderPressure() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18)))

        // Server/passer
        elements.append(.player(.partner, at: FieldPosition(x: 0.25, y: 0.50)))

        // Shooter receiving and shooting quickly
        let shooterPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.52, y: 0.45),  // Receive
                FieldPosition(x: 0.52, y: 0.42),  // Shoot
                FieldPosition(x: 0.50, y: 0.50)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: shooterPath))

        // Defender closing in
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.70, y: 0.55),
                FieldPosition(x: 0.58, y: 0.45),  // Closing
                FieldPosition(x: 0.70, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.70, y: 0.55), path: defenderPath))

        // Ball - pass then quick shot
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.28, y: 0.50),  // At server
                FieldPosition(x: 0.50, y: 0.48),  // Pass to shooter
                FieldPosition(x: 0.52, y: 0.10),  // Shot!
                FieldPosition(x: 0.28, y: 0.50)   // Reset
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.5, showHalfField: true)
    }

    /// Crossing and Finishing: Wide player crosses, striker finishes
    private static func crossingAndFinishing() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.17),
                FieldPosition(x: 0.55, y: 0.15),  // Comes for cross
                FieldPosition(x: 0.50, y: 0.17)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17), path: gkPath))

        // Wide player (crosser) on the right wing
        let crosserPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.85, y: 0.55),
                FieldPosition(x: 0.82, y: 0.45),
                FieldPosition(x: 0.78, y: 0.35),  // Delivery point
                FieldPosition(x: 0.85, y: 0.55)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.85, y: 0.55), path: crosserPath))

        // Striker making attacking run
        let strikerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.40, y: 0.50),
                FieldPosition(x: 0.45, y: 0.40),
                FieldPosition(x: 0.52, y: 0.28),  // Attacking the cross
                FieldPosition(x: 0.40, y: 0.50)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.40, y: 0.50), path: strikerPath))

        // Ball - wide then crossed in
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.83, y: 0.53),  // At winger
                FieldPosition(x: 0.80, y: 0.42),
                FieldPosition(x: 0.52, y: 0.26),  // Cross arrives
                FieldPosition(x: 0.50, y: 0.10),  // Header into goal!
                FieldPosition(x: 0.83, y: 0.53)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.83, y: 0.53), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.5, showHalfField: true)
    }

    /// Shooting Circuit: Multiple stations around the goal
    private static func shootingCircuit() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17)))

        // Station cones (3 shooting positions)
        elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.45)))  // Left
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.50)))  // Center
        elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.45)))  // Right

        // Player 1 at left station
        let p1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.48),
                FieldPosition(x: 0.32, y: 0.43),
                FieldPosition(x: 0.30, y: 0.48)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.48), path: p1Path))

        // Player 2 at center station
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.53)))

        // Player 3 at right station
        elements.append(.player(.teammate, at: FieldPosition(x: 0.70, y: 0.48)))

        // Ball - shots from different stations
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.45),
                FieldPosition(x: 0.45, y: 0.10),  // Left shot
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.50, y: 0.10),  // Center shot
                FieldPosition(x: 0.70, y: 0.45),
                FieldPosition(x: 0.55, y: 0.10),  // Right shot
                FieldPosition(x: 0.30, y: 0.45)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.30, y: 0.45), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 5.0, showHalfField: true)
    }

    /// Small-Sided Finishing Game: 3v3 with two goals
    private static func smallSidedFinishingGame() -> TacticalScene {
        var elements: [FieldElement] = []

        // Two goals
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .mini))
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.92), size: .mini))

        // Grid corners
        elements.append(.cone(at: FieldPosition(x: 0.20, y: 0.15)))
        elements.append(.cone(at: FieldPosition(x: 0.80, y: 0.15)))
        elements.append(.cone(at: FieldPosition(x: 0.20, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.80, y: 0.85)))

        // Team 1 (attacking up) - 3 players
        let att1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.35, y: 0.55),
                FieldPosition(x: 0.40, y: 0.45),
                FieldPosition(x: 0.35, y: 0.55)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.35, y: 0.55), path: att1Path))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.55, y: 0.45)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.65, y: 0.60)))

        // Team 2 (defending) - 3 players
        elements.append(.player(.defender, at: FieldPosition(x: 0.45, y: 0.35)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.55, y: 0.40)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.40, y: 0.50)))

        // Ball moving in game
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.38, y: 0.53),
                FieldPosition(x: 0.55, y: 0.43),
                FieldPosition(x: 0.50, y: 0.12),  // Goal!
                FieldPosition(x: 0.55, y: 0.55),
                FieldPosition(x: 0.38, y: 0.53)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.38, y: 0.53), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }
}

// MARK: - First Touch Exercises

extension ExerciseAnimationBuilder {

    /// Cushion Control: Receiving ball with different body parts
    private static func cushionControl() -> TacticalScene {
        var elements: [FieldElement] = []

        // Server throwing/passing balls
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.25)))

        // Receiver cushioning the ball
        let receiverPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.55),
                FieldPosition(x: 0.48, y: 0.52),  // Adjust for ball
                FieldPosition(x: 0.50, y: 0.50),  // Cushion
                FieldPosition(x: 0.50, y: 0.55)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.55), path: receiverPath))

        // Ball thrown at various heights, cushioned down
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.28),  // Thrown from server
                FieldPosition(x: 0.50, y: 0.40),  // In flight
                FieldPosition(x: 0.48, y: 0.50),  // Received (chest/thigh)
                FieldPosition(x: 0.48, y: 0.58),  // Cushioned to feet
                FieldPosition(x: 0.50, y: 0.28)   // Reset
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.28), path: ballPath))

        // Control zone markers
        elements.append(.cone(at: FieldPosition(x: 0.42, y: 0.58)))
        elements.append(.cone(at: FieldPosition(x: 0.58, y: 0.58)))

        return TacticalScene(elements: elements, loopDuration: 3.0)
    }

    /// Trap and Turn: Back to goal, receive and turn
    private static func trapAndTurn() -> TacticalScene {
        var elements: [FieldElement] = []

        // Passer behind the receiver
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.75)))

        // Target cone to play to after turn
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.25)))

        // Receiver with back to goal, traps and turns
        let receiverPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),  // Waiting
                FieldPosition(x: 0.50, y: 0.48),  // Check for ball
                FieldPosition(x: 0.55, y: 0.45),  // Receive and turn right
                FieldPosition(x: 0.50, y: 0.40),  // Face forward
                FieldPosition(x: 0.50, y: 0.50)   // Reset
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: receiverPath))

        // Ball trajectory - pass, trap, turn, play forward
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.72),  // At passer
                FieldPosition(x: 0.50, y: 0.52),  // Pass arrives
                FieldPosition(x: 0.55, y: 0.47),  // Trapped on turn
                FieldPosition(x: 0.50, y: 0.28),  // Played forward to target
                FieldPosition(x: 0.50, y: 0.72)   // Reset
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.72), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0)
    }

    /// Aerial Control: Controlling high balls
    private static func aerialControl() -> TacticalScene {
        var elements: [FieldElement] = []

        // Player controlling aerial balls
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.55),
                FieldPosition(x: 0.48, y: 0.50),  // Move to ball
                FieldPosition(x: 0.50, y: 0.48),  // Chest control
                FieldPosition(x: 0.50, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.55), path: playerPath))

        // Ball coming from high (self-toss simulation)
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.58),  // Tossed up
                FieldPosition(x: 0.50, y: 0.30),  // Peak height
                FieldPosition(x: 0.48, y: 0.45),  // Dropping
                FieldPosition(x: 0.48, y: 0.52),  // Chest control
                FieldPosition(x: 0.50, y: 0.60),  // At feet
                FieldPosition(x: 0.50, y: 0.58)   // Reset
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.58), path: ballPath))

        // Control zone
        elements.append(.cone(at: FieldPosition(x: 0.40, y: 0.60)))
        elements.append(.cone(at: FieldPosition(x: 0.60, y: 0.60)))

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }

    /// First Touch Under Pressure: Receiving with closing defender
    private static func firstTouchUnderPressure() -> TacticalScene {
        var elements: [FieldElement] = []

        // Passer
        elements.append(.player(.partner, at: FieldPosition(x: 0.25, y: 0.50)))

        // Receiver taking touch away from pressure
        let receiverPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.52, y: 0.48),  // Receive
                FieldPosition(x: 0.58, y: 0.45),  // Touch away from defender
                FieldPosition(x: 0.50, y: 0.50)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: receiverPath))

        // Defender closing in from behind
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.65, y: 0.55),
                FieldPosition(x: 0.55, y: 0.48),  // Pressing
                FieldPosition(x: 0.65, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.65, y: 0.55), path: defenderPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.28, y: 0.50),  // At passer
                FieldPosition(x: 0.50, y: 0.50),  // Arrives
                FieldPosition(x: 0.60, y: 0.43),  // Touched away
                FieldPosition(x: 0.28, y: 0.50)   // Reset
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.50), path: ballPath))

        // Grid markers
        elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.35)))
        elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.65)))

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }

    /// Control and Combine: A to B to C pattern
    private static func controlAndCombine() -> TacticalScene {
        var elements: [FieldElement] = []

        // Three players in a line
        let pA = FieldPosition(x: 0.25, y: 0.55)
        let pB = FieldPosition(x: 0.50, y: 0.45)
        let pC = FieldPosition(x: 0.75, y: 0.55)

        // Position markers
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.60)))
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.50)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.60)))

        // Player A
        elements.append(.player(.primary, at: pA))

        // Player B - receives, opens body, plays on
        let playerBPath = MovementPath(
            waypoints: [
                pB,
                FieldPosition(x: 0.52, y: 0.43),  // Receive
                FieldPosition(x: 0.54, y: 0.45),  // Open body
                pB
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: pB, path: playerBPath))

        // Player C
        elements.append(.player(.teammate, at: pC))

        // Ball: A -> B -> C -> B -> A
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.28, y: 0.53),  // At A
                FieldPosition(x: 0.50, y: 0.47),  // At B
                FieldPosition(x: 0.72, y: 0.53),  // At C
                FieldPosition(x: 0.50, y: 0.47),  // At B
                FieldPosition(x: 0.28, y: 0.53)   // At A
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.53), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }
}

// MARK: - Fitness Exercises

extension ExerciseAnimationBuilder {

    /// Ladder Agility Drills: Running through agility ladder
    private static func ladderAgilityDrills() -> TacticalScene {
        var elements: [FieldElement] = []

        // Agility ladder in center
        elements.append(.ladder(at: FieldPosition(x: 0.5, y: 0.5), rotation: .degrees(0)))

        // Player running through ladder with quick feet
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.85),
                FieldPosition(x: 0.50, y: 0.72),
                FieldPosition(x: 0.50, y: 0.60),
                FieldPosition(x: 0.50, y: 0.48),
                FieldPosition(x: 0.50, y: 0.36),
                FieldPosition(x: 0.50, y: 0.24),
                FieldPosition(x: 0.50, y: 0.15)
            ],
            duration: 2.5,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.85), path: playerPath))

        return TacticalScene(elements: elements, loopDuration: 2.5)
    }

    /// Shuttle Runs: Sprint between cones at 5, 10, 15m
    private static func shuttleRuns() -> TacticalScene {
        var elements: [FieldElement] = []

        // Cones at different distances
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.85)))  // Start
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.65)))  // 5m
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.45)))  // 10m
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.25)))  // 15m

        // Player doing shuttle runs
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.82),  // Start
                FieldPosition(x: 0.50, y: 0.65),  // Touch 5m
                FieldPosition(x: 0.50, y: 0.82),  // Back
                FieldPosition(x: 0.50, y: 0.45),  // Touch 10m
                FieldPosition(x: 0.50, y: 0.82),  // Back
                FieldPosition(x: 0.50, y: 0.25),  // Touch 15m
                FieldPosition(x: 0.50, y: 0.82)   // Back
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.82), path: playerPath))

        return TacticalScene(elements: elements, loopDuration: 5.0)
    }

    /// Box Jumps: Jumping onto platform
    private static func boxJumps() -> TacticalScene {
        var elements: [FieldElement] = []

        // Hurdles as boxes/platforms
        elements.append(.hurdle(at: FieldPosition(x: 0.50, y: 0.45)))

        // Player jumping up and stepping down
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.60),  // Ground start
                FieldPosition(x: 0.50, y: 0.52),  // Crouch
                FieldPosition(x: 0.50, y: 0.40),  // On top of box
                FieldPosition(x: 0.55, y: 0.50),  // Step down side
                FieldPosition(x: 0.50, y: 0.60)   // Return
            ],
            duration: 2.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.60), path: playerPath))

        return TacticalScene(elements: elements, loopDuration: 2.5)
    }

    /// Sprint Recovery Intervals: Sprint then jog
    private static func sprintRecoveryIntervals() -> TacticalScene {
        var elements: [FieldElement] = []

        // Track markers
        elements.append(.cone(at: FieldPosition(x: 0.20, y: 0.50)))
        elements.append(.cone(at: FieldPosition(x: 0.80, y: 0.50)))

        // Player sprinting then jogging
        let playerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.22, y: 0.50),  // Start
                FieldPosition(x: 0.50, y: 0.50),  // Sprint
                FieldPosition(x: 0.78, y: 0.50),  // End sprint
                FieldPosition(x: 0.65, y: 0.55),  // Jog recovery
                FieldPosition(x: 0.50, y: 0.58),
                FieldPosition(x: 0.35, y: 0.55),
                FieldPosition(x: 0.22, y: 0.50)   // Back to start
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.22, y: 0.50), path: playerPath))

        return TacticalScene(elements: elements, loopDuration: 5.0)
    }

    /// Partner Sprint Races: Two players racing
    private static func partnerSprintRaces() -> TacticalScene {
        var elements: [FieldElement] = []

        // Start and finish cones for two lanes
        elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.85)))
        elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.15)))
        elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.15)))

        // Player 1 (left lane)
        let player1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.38, y: 0.82),
                FieldPosition(x: 0.38, y: 0.18)
            ],
            duration: 2.0,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.38, y: 0.82), path: player1Path))

        // Player 2 (right lane)
        let player2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.62, y: 0.82),
                FieldPosition(x: 0.62, y: 0.18)
            ],
            duration: 2.1,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.62, y: 0.82), path: player2Path))

        return TacticalScene(elements: elements, loopDuration: 2.1)
    }

    /// Resistance Band Partner Runs: Player running against resistance
    private static func resistanceBandRuns() -> TacticalScene {
        var elements: [FieldElement] = []

        // Start and end markers
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.75)))
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.25)))

        // Runner in front
        let runnerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.65),
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.50, y: 0.65)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.65), path: runnerPath))

        // Partner providing resistance from behind
        let partnerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.72),
                FieldPosition(x: 0.50, y: 0.45),
                FieldPosition(x: 0.50, y: 0.72)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.72), path: partnerPath))

        return TacticalScene(elements: elements, loopDuration: 3.0)
    }

    /// Team Fitness Circuit: Multiple stations with players
    private static func teamFitnessCircuit() -> TacticalScene {
        var elements: [FieldElement] = []

        // Station 1: Ladder
        elements.append(.ladder(at: FieldPosition(x: 0.25, y: 0.35), rotation: .degrees(0)))
        let p1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.25, y: 0.55),
                FieldPosition(x: 0.25, y: 0.20)
            ],
            duration: 2.0,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.25, y: 0.55), path: p1Path))

        // Station 2: Hurdles
        elements.append(.hurdle(at: FieldPosition(x: 0.50, y: 0.30)))
        elements.append(.hurdle(at: FieldPosition(x: 0.50, y: 0.45)))
        elements.append(.hurdle(at: FieldPosition(x: 0.50, y: 0.60)))
        let p2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.75),
                FieldPosition(x: 0.50, y: 0.20)
            ],
            duration: 2.0,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.75), path: p2Path))

        // Station 3: Cone sprints
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.65)))
        let p3Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.75, y: 0.70),
                FieldPosition(x: 0.75, y: 0.25)
            ],
            duration: 2.0,
            repeatBehavior: .pingPong,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.75, y: 0.70), path: p3Path))

        return TacticalScene(elements: elements, loopDuration: 2.0)
    }
}

// MARK: - Goalkeeping Exercises

extension ExerciseAnimationBuilder {

    /// Diving Save Practice: Diving to save shots in corners
    private static func divingSavePractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        // Goalkeeper diving left and right
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.20),
                FieldPosition(x: 0.35, y: 0.22),  // Dive left
                FieldPosition(x: 0.50, y: 0.20),
                FieldPosition(x: 0.65, y: 0.22),  // Dive right
                FieldPosition(x: 0.50, y: 0.20)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.20), path: gkPath))

        // Shooter
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.55)))

        // Shots alternating to corners
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.52),
                FieldPosition(x: 0.38, y: 0.12),  // Shot to left
                FieldPosition(x: 0.50, y: 0.52),
                FieldPosition(x: 0.62, y: 0.12),  // Shot to right
                FieldPosition(x: 0.50, y: 0.52)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.52), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Distribution Practice: GK throwing and kicking to targets
    private static func distributionPractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.22),
                FieldPosition(x: 0.45, y: 0.25),  // Pick up
                FieldPosition(x: 0.50, y: 0.22),  // Throw
                FieldPosition(x: 0.55, y: 0.25),  // Pick up
                FieldPosition(x: 0.50, y: 0.22)   // Kick
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.22), path: gkPath))

        // Target cones
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.70)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.70)))

        // Ball being distributed
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.25),
                FieldPosition(x: 0.28, y: 0.68),  // Throw to left
                FieldPosition(x: 0.50, y: 0.25),
                FieldPosition(x: 0.72, y: 0.68),  // Kick to right
                FieldPosition(x: 0.50, y: 0.25)
            ],
            duration: 5.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.25), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 5.0, showHalfField: true)
    }

    /// Shot Stopping Reactions: Rapid close-range saves
    private static func shotStoppingReactions() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        // Goalkeeper reacting quickly
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.20),
                FieldPosition(x: 0.45, y: 0.18),  // Left
                FieldPosition(x: 0.50, y: 0.20),
                FieldPosition(x: 0.55, y: 0.18),  // Right
                FieldPosition(x: 0.50, y: 0.22),  // Low
                FieldPosition(x: 0.50, y: 0.20)
            ],
            duration: 2.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.20), path: gkPath))

        // Close-range shooter
        elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.38)))

        // Rapid shots
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.42, y: 0.12),  // Left
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.58, y: 0.12),  // Right
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.50, y: 0.15),  // Center
                FieldPosition(x: 0.50, y: 0.35)
            ],
            duration: 2.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.35), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 2.5, showHalfField: true)
    }

    /// Goalkeeper Communication Drill: Organizing defense
    private static func goalkeeperCommunication() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        // Goalkeeper commanding
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.18),
                FieldPosition(x: 0.55, y: 0.16),  // Come for cross
                FieldPosition(x: 0.50, y: 0.18)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18), path: gkPath))

        // Defenders
        elements.append(.player(.partner, at: FieldPosition(x: 0.35, y: 0.28)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.65, y: 0.28)))

        // Attacker
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.32)))

        // Crosser
        elements.append(.player(.defender, at: FieldPosition(x: 0.88, y: 0.40)))

        // Cross coming in
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.85, y: 0.38),
                FieldPosition(x: 0.55, y: 0.18),  // GK claims!
                FieldPosition(x: 0.85, y: 0.38)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.85, y: 0.38), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }
}

// MARK: - Defending Exercises

extension ExerciseAnimationBuilder {

    /// 1v1 Defending: Jockeying an attacker
    private static func oneVOneDefending() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        // Grid markers
        elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.70)))
        elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.70)))

        // Defender jockeying
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.40),
                FieldPosition(x: 0.45, y: 0.42),
                FieldPosition(x: 0.55, y: 0.38),
                FieldPosition(x: 0.50, y: 0.40)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.40), path: defenderPath))

        // Attacker
        let attackerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.60),
                FieldPosition(x: 0.42, y: 0.52),
                FieldPosition(x: 0.58, y: 0.48),
                FieldPosition(x: 0.50, y: 0.60)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.60), path: attackerPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.63),
                FieldPosition(x: 0.42, y: 0.55),
                FieldPosition(x: 0.58, y: 0.51),
                FieldPosition(x: 0.50, y: 0.63)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.63), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Defensive Positioning: Line shifting with ball
    private static func defensivePositioning() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.25, y: 0.62),
                FieldPosition(x: 0.75, y: 0.62),
                FieldPosition(x: 0.25, y: 0.62)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.25, y: 0.62), path: ballPath))

        // Attackers
        elements.append(.player(.defender, at: FieldPosition(x: 0.25, y: 0.60)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.68)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.75, y: 0.60)))

        // Defensive line shifting
        let d1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.35),
                FieldPosition(x: 0.55, y: 0.35),
                FieldPosition(x: 0.30, y: 0.35)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.35), path: d1Path))

        let d2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.38),
                FieldPosition(x: 0.65, y: 0.38),
                FieldPosition(x: 0.45, y: 0.38)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.45, y: 0.38), path: d2Path))

        let d3Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.55, y: 0.35),
                FieldPosition(x: 0.75, y: 0.35),
                FieldPosition(x: 0.55, y: 0.35)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.55, y: 0.35), path: d3Path))

        return TacticalScene(elements: elements, loopDuration: 4.5, showHalfField: true)
    }

    /// Clearance Practice: Clearing balls under pressure
    private static func clearancePractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        // Defender
        let defenderPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.38),
                FieldPosition(x: 0.48, y: 0.35),
                FieldPosition(x: 0.50, y: 0.32),  // Clear!
                FieldPosition(x: 0.50, y: 0.38)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.38), path: defenderPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.65),
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.55, y: 0.75),  // Cleared!
                FieldPosition(x: 0.50, y: 0.65)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.65), path: ballPath))

        // Attacker
        let attackerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.55),
                FieldPosition(x: 0.52, y: 0.45),
                FieldPosition(x: 0.50, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.55), path: attackerPath))

        return TacticalScene(elements: elements, loopDuration: 3.5, showHalfField: true)
    }

    /// 2v2 Defending: Two defenders vs two attackers
    private static func twoVTwoDefending() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        // Grid
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.25)))
        elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.70)))
        elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.70)))

        // Defender 1
        let d1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.40),
                FieldPosition(x: 0.40, y: 0.48),
                FieldPosition(x: 0.45, y: 0.40)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.45, y: 0.40), path: d1Path))

        // Defender 2
        let d2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.55, y: 0.35),
                FieldPosition(x: 0.50, y: 0.38),
                FieldPosition(x: 0.55, y: 0.35)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.55, y: 0.35), path: d2Path))

        // Attackers
        let a1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.40, y: 0.55),
                FieldPosition(x: 0.45, y: 0.50),
                FieldPosition(x: 0.40, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.40, y: 0.55), path: a1Path))

        let a2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.60, y: 0.55),
                FieldPosition(x: 0.55, y: 0.45),
                FieldPosition(x: 0.60, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.60, y: 0.55), path: a2Path))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.42, y: 0.53),
                FieldPosition(x: 0.55, y: 0.47),
                FieldPosition(x: 0.42, y: 0.53)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.42, y: 0.53), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.5, showHalfField: true)
    }

    /// Pressing Triggers: Team pressing together
    private static func pressingTriggers() -> TacticalScene {
        var elements: [FieldElement] = []

        // Ball carrier
        let ballCarrierPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.70),
                FieldPosition(x: 0.48, y: 0.68),  // Bad touch!
                FieldPosition(x: 0.50, y: 0.70)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.70), path: ballCarrierPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.73),
                FieldPosition(x: 0.52, y: 0.72),
                FieldPosition(x: 0.50, y: 0.65),  // Won!
                FieldPosition(x: 0.50, y: 0.73)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.73), path: ballPath))

        // Pressing team
        let p1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.50, y: 0.62),  // Press!
                FieldPosition(x: 0.50, y: 0.50)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: p1Path))

        let p2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.35, y: 0.55),
                FieldPosition(x: 0.40, y: 0.65),
                FieldPosition(x: 0.35, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.35, y: 0.55), path: p2Path))

        let p3Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.65, y: 0.55),
                FieldPosition(x: 0.60, y: 0.65),
                FieldPosition(x: 0.65, y: 0.55)
            ],
            duration: 3.5,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.65, y: 0.55), path: p3Path))

        // Opponents
        elements.append(.player(.defender, at: FieldPosition(x: 0.30, y: 0.75)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.70, y: 0.75)))

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }
}

// MARK: - Set Pieces Exercises

extension ExerciseAnimationBuilder {

    /// Free Kick Technique: Bending ball around wall
    private static func freeKickTechnique() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.17),
                FieldPosition(x: 0.60, y: 0.15),  // Dive
                FieldPosition(x: 0.50, y: 0.17)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17), path: gkPath))

        // Wall
        elements.append(.mannequin(at: FieldPosition(x: 0.40, y: 0.35)))
        elements.append(.mannequin(at: FieldPosition(x: 0.48, y: 0.35)))
        elements.append(.mannequin(at: FieldPosition(x: 0.56, y: 0.35)))

        // Kicker
        let kickerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.38, y: 0.58),
                FieldPosition(x: 0.42, y: 0.52),
                FieldPosition(x: 0.45, y: 0.48),  // Strike
                FieldPosition(x: 0.38, y: 0.58)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.38, y: 0.58), path: kickerPath))

        // Ball curving
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.50),
                FieldPosition(x: 0.45, y: 0.50),
                FieldPosition(x: 0.62, y: 0.30),  // Curve
                FieldPosition(x: 0.62, y: 0.10),  // Goal!
                FieldPosition(x: 0.45, y: 0.50)
            ],
            duration: 4.5,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.45, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.5, showHalfField: true)
    }

    /// Corner Delivery: Delivering corners
    private static func cornerDelivery() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.16)))

        // Corner taker
        let cornerTakerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.95, y: 0.05),
                FieldPosition(x: 0.92, y: 0.08),
                FieldPosition(x: 0.95, y: 0.05)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.95, y: 0.05), path: cornerTakerPath))

        // Attackers
        let att1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.55, y: 0.45),
                FieldPosition(x: 0.52, y: 0.25),
                FieldPosition(x: 0.55, y: 0.45)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.55, y: 0.45), path: att1Path))

        let att2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.40, y: 0.50),
                FieldPosition(x: 0.38, y: 0.28),
                FieldPosition(x: 0.40, y: 0.50)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.40, y: 0.50), path: att2Path))

        // Defenders
        elements.append(.player(.defender, at: FieldPosition(x: 0.48, y: 0.30)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.42, y: 0.32)))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.92, y: 0.05),
                FieldPosition(x: 0.92, y: 0.05),
                FieldPosition(x: 0.52, y: 0.22),
                FieldPosition(x: 0.50, y: 0.10),  // Goal!
                FieldPosition(x: 0.92, y: 0.05)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.92, y: 0.05), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Penalty Practice: Taking penalties
    private static func penaltyPractice() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.17),
                FieldPosition(x: 0.50, y: 0.17),
                FieldPosition(x: 0.62, y: 0.15),  // Dive
                FieldPosition(x: 0.50, y: 0.17)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17), path: gkPath))

        // Penalty taker
        let kickerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.55),
                FieldPosition(x: 0.50, y: 0.50),
                FieldPosition(x: 0.50, y: 0.45),  // Strike
                FieldPosition(x: 0.50, y: 0.55)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.55), path: kickerPath))

        // Penalty spot
        elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.38)))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.40),
                FieldPosition(x: 0.50, y: 0.40),
                FieldPosition(x: 0.50, y: 0.40),
                FieldPosition(x: 0.40, y: 0.10),  // Goal!
                FieldPosition(x: 0.50, y: 0.40)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.40), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Throw-In Routines: Practicing throw-ins
    private static func throwInRoutines() -> TacticalScene {
        var elements: [FieldElement] = []

        // Sideline markers
        elements.append(.cone(at: FieldPosition(x: 0.05, y: 0.40)))
        elements.append(.cone(at: FieldPosition(x: 0.05, y: 0.60)))

        // Thrower
        let throwerPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.08, y: 0.50),
                FieldPosition(x: 0.08, y: 0.48),
                FieldPosition(x: 0.08, y: 0.50)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.primary, at: FieldPosition(x: 0.08, y: 0.50), path: throwerPath))

        // Receiver
        let receiverPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.30, y: 0.50),
                FieldPosition(x: 0.25, y: 0.45),
                FieldPosition(x: 0.20, y: 0.52),
                FieldPosition(x: 0.30, y: 0.50)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.30, y: 0.50), path: receiverPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.10, y: 0.50),
                FieldPosition(x: 0.10, y: 0.50),
                FieldPosition(x: 0.22, y: 0.50),
                FieldPosition(x: 0.10, y: 0.50)
            ],
            duration: 3.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.10, y: 0.50), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 3.0)
    }

    /// Set Piece Attacking Routines: Coordinated runs
    private static func setPieceAttackingRoutines() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.16)))

        // Corner taker
        elements.append(.player(.primary, at: FieldPosition(x: 0.92, y: 0.05)))

        // Attackers making runs
        let att1Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.60, y: 0.45),
                FieldPosition(x: 0.55, y: 0.25),
                FieldPosition(x: 0.60, y: 0.45)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.partner, at: FieldPosition(x: 0.60, y: 0.45), path: att1Path))

        let att2Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.45, y: 0.50),
                FieldPosition(x: 0.40, y: 0.30),
                FieldPosition(x: 0.45, y: 0.50)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.45, y: 0.50), path: att2Path))

        let att3Path = MovementPath(
            waypoints: [
                FieldPosition(x: 0.35, y: 0.45),
                FieldPosition(x: 0.50, y: 0.35),
                FieldPosition(x: 0.35, y: 0.45)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.35, y: 0.45), path: att3Path))

        // Decoy
        let decoyPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.70, y: 0.40),
                FieldPosition(x: 0.65, y: 0.28),
                FieldPosition(x: 0.70, y: 0.40)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .linear
        )
        elements.append(.player(.teammate, at: FieldPosition(x: 0.70, y: 0.40), path: decoyPath))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.90, y: 0.05),
                FieldPosition(x: 0.90, y: 0.05),
                FieldPosition(x: 0.55, y: 0.22),
                FieldPosition(x: 0.52, y: 0.10),  // Goal!
                FieldPosition(x: 0.90, y: 0.05)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.90, y: 0.05), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    /// Defensive Set Piece Organization: Defending corners/FKs
    private static func defensiveSetPieceOrganization() -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.08), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.16),
                FieldPosition(x: 0.52, y: 0.14),  // Punch
                FieldPosition(x: 0.50, y: 0.16)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.16), path: gkPath))

        // Defenders
        elements.append(.player(.primary, at: FieldPosition(x: 0.35, y: 0.22)))
        elements.append(.player(.partner, at: FieldPosition(x: 0.45, y: 0.28)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.55, y: 0.28)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.65, y: 0.22)))
        elements.append(.player(.teammate, at: FieldPosition(x: 0.50, y: 0.40)))

        // Attackers
        elements.append(.player(.defender, at: FieldPosition(x: 0.40, y: 0.32)))
        elements.append(.player(.defender, at: FieldPosition(x: 0.60, y: 0.32)))

        // Corner taker
        elements.append(.player(.defender, at: FieldPosition(x: 0.92, y: 0.05)))

        // Ball
        let ballPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.90, y: 0.05),
                FieldPosition(x: 0.52, y: 0.18),
                FieldPosition(x: 0.55, y: 0.50),  // Cleared!
                FieldPosition(x: 0.90, y: 0.05)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.ball(at: FieldPosition(x: 0.90, y: 0.05), path: ballPath))

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }
}
