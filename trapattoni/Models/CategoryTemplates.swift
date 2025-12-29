import Foundation
import SwiftUI

/// Builds tactical scenes based on exercise category and parameters
struct CategoryTemplateBuilder {

    // MARK: - Main Builder

    static func buildScene(
        for category: ExerciseCategory,
        trainingType: TrainingType,
        equipment: [Equipment],
        skillLevel: SkillLevel
    ) -> TacticalScene {
        switch category {
        case .dribbling:
            return buildDribblingScene(trainingType: trainingType, equipment: equipment)
        case .passing:
            return buildPassingScene(trainingType: trainingType, equipment: equipment)
        case .shooting:
            return buildShootingScene(trainingType: trainingType, equipment: equipment)
        case .firstTouch:
            return buildFirstTouchScene(trainingType: trainingType, equipment: equipment)
        case .fitnessConditioning:
            return buildFitnessScene(trainingType: trainingType, equipment: equipment)
        case .goalkeeping:
            return buildGoalkeepingScene(trainingType: trainingType, equipment: equipment)
        case .defending:
            return buildDefendingScene(trainingType: trainingType, equipment: equipment)
        case .setPieces:
            return buildSetPiecesScene(trainingType: trainingType, equipment: equipment)
        }
    }

    // MARK: - Dribbling Template
    // Solo: Cone weave - player dribbles through line of cones
    // Partner: 1v1 battle - attacker vs defender in grid
    // Team: Rondo - keep ball away from defender in circle

    private static func buildDribblingScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        switch trainingType {
        case .solo:
            // Cone Weave: 6 cones in a vertical line, player weaves through
            let coneX: CGFloat = 0.5
            let coneSpacing: CGFloat = 0.10
            let startY: CGFloat = 0.80

            // Place cones in a straight vertical line
            for i in 0..<6 {
                let coneY = startY - CGFloat(i) * coneSpacing
                elements.append(.cone(at: FieldPosition(x: coneX, y: coneY)))
            }

            // Player weaves left-right through cones
            let playerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.45, y: 0.88),  // Start left of first cone
                    FieldPosition(x: 0.55, y: 0.75),  // Right of cone 1
                    FieldPosition(x: 0.45, y: 0.65),  // Left of cone 2
                    FieldPosition(x: 0.55, y: 0.55),  // Right of cone 3
                    FieldPosition(x: 0.45, y: 0.45),  // Left of cone 4
                    FieldPosition(x: 0.55, y: 0.35),  // Right of cone 5
                    FieldPosition(x: 0.45, y: 0.25),  // Left of cone 6
                    FieldPosition(x: 0.50, y: 0.18)   // End at top
                ],
                duration: 5.0,
                repeatBehavior: .pingPong,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.45, y: 0.88), path: playerPath))

            // Ball follows player closely
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.45, y: 0.91),
                    FieldPosition(x: 0.55, y: 0.78),
                    FieldPosition(x: 0.45, y: 0.68),
                    FieldPosition(x: 0.55, y: 0.58),
                    FieldPosition(x: 0.45, y: 0.48),
                    FieldPosition(x: 0.55, y: 0.38),
                    FieldPosition(x: 0.45, y: 0.28),
                    FieldPosition(x: 0.50, y: 0.21)
                ],
                duration: 5.0,
                repeatBehavior: .pingPong,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.45, y: 0.91), path: ballPath))

        case .partner:
            // 1v1 Battle: Attacker tries to dribble past defender
            // Grid marked by 4 cones
            elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.30)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.30)))
            elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.70)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.70)))

            // Attacker with ball trying to beat defender
            let attackerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.75),
                    FieldPosition(x: 0.40, y: 0.60),  // Feint left
                    FieldPosition(x: 0.60, y: 0.50),  // Go right
                    FieldPosition(x: 0.50, y: 0.35),  // Break through
                    FieldPosition(x: 0.50, y: 0.75)   // Reset
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.75), path: attackerPath))

            // Ball with attacker
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.78),
                    FieldPosition(x: 0.40, y: 0.63),
                    FieldPosition(x: 0.60, y: 0.53),
                    FieldPosition(x: 0.50, y: 0.38),
                    FieldPosition(x: 0.50, y: 0.78)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.78), path: ballPath))

            // Defender trying to block
            let defenderPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.50),
                    FieldPosition(x: 0.42, y: 0.52),  // Shift to block
                    FieldPosition(x: 0.55, y: 0.48),  // Get beaten
                    FieldPosition(x: 0.50, y: 0.45),
                    FieldPosition(x: 0.50, y: 0.50)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.50), path: defenderPath))

        case .team:
            // Rondo: Players in circle, 1-2 defenders in middle
            // Outer players passing around defenders
            let radius: CGFloat = 0.28
            let centerX: CGFloat = 0.5
            let centerY: CGFloat = 0.5

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
                    FieldPosition(x: 0.45, y: 0.55),
                    FieldPosition(x: 0.50, y: 0.50)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.50), path: defenderPath))

            // Ball moving around the circle
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: centerX, y: centerY - radius),
                    FieldPosition(x: centerX + radius * 0.95, y: centerY - radius * 0.31),
                    FieldPosition(x: centerX + radius * 0.59, y: centerY + radius * 0.81),
                    FieldPosition(x: centerX - radius * 0.59, y: centerY + radius * 0.81),
                    FieldPosition(x: centerX - radius * 0.95, y: centerY - radius * 0.31),
                    FieldPosition(x: centerX, y: centerY - radius)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: centerX, y: centerY - radius), path: ballPath))
        }

        return TacticalScene(elements: elements, loopDuration: trainingType == .solo ? 5.0 : 4.0)
    }

    // MARK: - Passing Template
    // Solo: Wall passing - player passes to wall and receives rebound
    // Partner: Two players passing back and forth
    // Team: Triangle/Square passing with movement

    private static func buildPassingScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        switch trainingType {
        case .solo:
            // Wall Passing: Player 3-5m from wall, passing and receiving
            elements.append(.wall(at: FieldPosition(x: 0.5, y: 0.18)))

            // Player moves side to side while passing
            let playerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.45, y: 0.60),
                    FieldPosition(x: 0.50, y: 0.58),
                    FieldPosition(x: 0.55, y: 0.60),
                    FieldPosition(x: 0.50, y: 0.58),
                    FieldPosition(x: 0.45, y: 0.60)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.45, y: 0.60), path: playerPath))

            // Ball goes to wall and back
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.45, y: 0.55),  // At player
                    FieldPosition(x: 0.48, y: 0.22),  // Hit wall
                    FieldPosition(x: 0.50, y: 0.53),  // Back to player
                    FieldPosition(x: 0.52, y: 0.22),  // Hit wall
                    FieldPosition(x: 0.55, y: 0.55),  // Back to player
                    FieldPosition(x: 0.52, y: 0.22),  // Hit wall
                    FieldPosition(x: 0.50, y: 0.53),  // Back
                    FieldPosition(x: 0.48, y: 0.22),  // Hit wall
                    FieldPosition(x: 0.45, y: 0.55)   // Back to start
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.45, y: 0.55), path: ballPath))

        case .partner:
            // Two Player Passing: 10-15m apart, passing back and forth
            // Player 1 (left)
            let player1Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.25, y: 0.50),
                    FieldPosition(x: 0.28, y: 0.48),
                    FieldPosition(x: 0.25, y: 0.50)
                ],
                duration: 2.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.25, y: 0.50), path: player1Path))

            // Player 2 (right)
            let player2Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.75, y: 0.50),
                    FieldPosition(x: 0.72, y: 0.52),
                    FieldPosition(x: 0.75, y: 0.50)
                ],
                duration: 2.0,
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
                duration: 2.0,
                repeatBehavior: .pingPong,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.50), path: ballPath))

            // Distance markers
            elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.45)))
            elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.45)))

        case .team:
            // Triangle Passing: 3 players in triangle, pass and follow
            let p1 = FieldPosition(x: 0.50, y: 0.28)  // Top
            let p2 = FieldPosition(x: 0.28, y: 0.68)  // Bottom left
            let p3 = FieldPosition(x: 0.72, y: 0.68)  // Bottom right

            // Cones marking positions
            elements.append(.cone(at: p1))
            elements.append(.cone(at: p2))
            elements.append(.cone(at: p3))

            // Players move to next position after passing
            let player1Path = MovementPath(
                waypoints: [p1, p2, p3, p1],
                duration: 4.5,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.primary, at: p1, path: player1Path))

            let player2Path = MovementPath(
                waypoints: [p2, p3, p1, p2],
                duration: 4.5,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.partner, at: p2, path: player2Path))

            let player3Path = MovementPath(
                waypoints: [p3, p1, p2, p3],
                duration: 4.5,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.teammate, at: p3, path: player3Path))

            // Ball circulates around triangle
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.32),
                    FieldPosition(x: 0.32, y: 0.65),
                    FieldPosition(x: 0.68, y: 0.65),
                    FieldPosition(x: 0.50, y: 0.32)
                ],
                duration: 4.5,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.32), path: ballPath))
        }

        return TacticalScene(elements: elements, loopDuration: trainingType == .team ? 4.5 : 3.0)
    }

    // MARK: - Shooting Template
    // Solo: Approach and shoot at goal
    // Partner: Receive pass and shoot
    // Team: Combination play ending in shot

    private static func buildShootingScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal at top
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        // Goalkeeper
        let gkPath = MovementPath(
            waypoints: [
                FieldPosition(x: 0.50, y: 0.18),
                FieldPosition(x: 0.42, y: 0.18),
                FieldPosition(x: 0.58, y: 0.18),
                FieldPosition(x: 0.50, y: 0.18)
            ],
            duration: 4.0,
            repeatBehavior: .loop,
            pathType: .curved
        )
        elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18), path: gkPath))

        switch trainingType {
        case .solo:
            // Finesse/Power Shot: Approach from edge of box and shoot
            let shooterPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.35, y: 0.70),  // Start wide
                    FieldPosition(x: 0.42, y: 0.55),  // Approach
                    FieldPosition(x: 0.48, y: 0.42),  // Shooting position
                    FieldPosition(x: 0.48, y: 0.42),  // Strike (pause)
                    FieldPosition(x: 0.35, y: 0.70)   // Return
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.35, y: 0.70), path: shooterPath))

            // Ball - dribble in then shoot
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.35, y: 0.73),
                    FieldPosition(x: 0.42, y: 0.58),
                    FieldPosition(x: 0.48, y: 0.45),
                    FieldPosition(x: 0.55, y: 0.12),  // Shot to goal!
                    FieldPosition(x: 0.35, y: 0.73)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.35, y: 0.73), path: ballPath))

            // Cones marking shooting zone
            elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.40)))
            elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.40)))

        case .partner:
            // Crossing and Finishing: One crosses, other shoots
            // Crosser on the wing
            let crosserPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.85, y: 0.60),
                    FieldPosition(x: 0.80, y: 0.45),
                    FieldPosition(x: 0.75, y: 0.35),  // Delivery point
                    FieldPosition(x: 0.85, y: 0.60)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.partner, at: FieldPosition(x: 0.85, y: 0.60), path: crosserPath))

            // Striker making run into box
            let strikerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.40, y: 0.55),  // Start position
                    FieldPosition(x: 0.45, y: 0.45),
                    FieldPosition(x: 0.52, y: 0.32),  // Attacking position
                    FieldPosition(x: 0.40, y: 0.55)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.40, y: 0.55), path: strikerPath))

            // Ball - wide then crossed in for finish
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.82, y: 0.58),
                    FieldPosition(x: 0.78, y: 0.42),
                    FieldPosition(x: 0.52, y: 0.30),  // Cross arrives
                    FieldPosition(x: 0.50, y: 0.12),  // Shot!
                    FieldPosition(x: 0.82, y: 0.58)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.82, y: 0.58), path: ballPath))

        case .team:
            // Combination Play: Quick passing then shot
            // Midfielder at center
            elements.append(.player(.teammate, at: FieldPosition(x: 0.50, y: 0.60)))

            // Striker making run
            let strikerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.55, y: 0.50),
                    FieldPosition(x: 0.50, y: 0.38),
                    FieldPosition(x: 0.48, y: 0.30),
                    FieldPosition(x: 0.55, y: 0.50)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.55, y: 0.50), path: strikerPath))

            // Supporting player
            let supportPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.35, y: 0.55),
                    FieldPosition(x: 0.40, y: 0.48),
                    FieldPosition(x: 0.35, y: 0.55)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.partner, at: FieldPosition(x: 0.35, y: 0.55), path: supportPath))

            // Ball - passes then shot
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.58),  // At midfielder
                    FieldPosition(x: 0.38, y: 0.52),  // To support
                    FieldPosition(x: 0.50, y: 0.40),  // To striker
                    FieldPosition(x: 0.48, y: 0.12),  // Shot!
                    FieldPosition(x: 0.50, y: 0.58)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.58), path: ballPath))

            // Defender
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.35)))
        }

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    // MARK: - First Touch Template
    // Solo: Control aerial ball
    // Partner: Receive pass and control
    // Team: Control and combine pattern

    private static func buildFirstTouchScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        switch trainingType {
        case .solo:
            // Aerial Control: Ball coming from height, player controls
            // Rebounder or self-toss simulation
            if equipment.contains(.rebounder) {
                elements.append(.rebounder(at: FieldPosition(x: 0.5, y: 0.22), rotation: .degrees(0)))
            }

            // Player receiving and controlling
            let playerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.58),
                    FieldPosition(x: 0.50, y: 0.52),  // Move to ball
                    FieldPosition(x: 0.48, y: 0.55),  // Control touch
                    FieldPosition(x: 0.50, y: 0.58)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.58), path: playerPath))

            // Ball arriving and being cushioned
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.28),  // From rebounder/air
                    FieldPosition(x: 0.50, y: 0.50),  // Arrives at player
                    FieldPosition(x: 0.48, y: 0.58),  // Controlled at feet
                    FieldPosition(x: 0.50, y: 0.28)   // Played back
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.28), path: ballPath))

            // Control zone cones
            elements.append(.cone(at: FieldPosition(x: 0.42, y: 0.60)))
            elements.append(.cone(at: FieldPosition(x: 0.58, y: 0.60)))

        case .partner:
            // Trap and Turn: Back to goal, receive, turn, play forward
            // Passer
            elements.append(.player(.partner, at: FieldPosition(x: 0.50, y: 0.75)))

            // Receiver with back to goal, traps and turns
            let receiverPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.50),  // Receive position
                    FieldPosition(x: 0.50, y: 0.48),  // Receive
                    FieldPosition(x: 0.55, y: 0.45),  // Turn right
                    FieldPosition(x: 0.50, y: 0.42),  // Face forward
                    FieldPosition(x: 0.50, y: 0.50)   // Reset
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.50), path: receiverPath))

            // Ball trajectory
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.72),  // At passer
                    FieldPosition(x: 0.50, y: 0.52),  // Arrives at receiver
                    FieldPosition(x: 0.55, y: 0.48),  // Controlled on turn
                    FieldPosition(x: 0.50, y: 0.35),  // Played forward
                    FieldPosition(x: 0.50, y: 0.72)   // Reset
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.72), path: ballPath))

            // Cone target to play to after turn
            elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.30)))

        case .team:
            // Control and Combine: 3 players, A to B to C pattern
            let pA = FieldPosition(x: 0.25, y: 0.60)
            let pB = FieldPosition(x: 0.50, y: 0.45)
            let pC = FieldPosition(x: 0.75, y: 0.60)

            elements.append(.player(.primary, at: pA))

            // Player B receives and plays on
            let playerBPath = MovementPath(
                waypoints: [
                    pB,
                    FieldPosition(x: 0.52, y: 0.43),  // Receive
                    FieldPosition(x: 0.54, y: 0.45),  // Open body
                    pB
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.partner, at: pB, path: playerBPath))

            elements.append(.player(.teammate, at: pC))

            // Ball: A -> B -> C and back
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.28, y: 0.58),  // At A
                    FieldPosition(x: 0.50, y: 0.47),  // At B
                    FieldPosition(x: 0.72, y: 0.58),  // At C
                    FieldPosition(x: 0.50, y: 0.47),  // At B
                    FieldPosition(x: 0.28, y: 0.58)   // At A
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.28, y: 0.58), path: ballPath))

            // Position markers
            elements.append(.cone(at: FieldPosition(x: 0.25, y: 0.65)))
            elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.50)))
            elements.append(.cone(at: FieldPosition(x: 0.75, y: 0.65)))
        }

        return TacticalScene(elements: elements, loopDuration: 3.5)
    }

    // MARK: - Fitness Template
    // Solo: Ladder agility drills / shuttle runs
    // Partner: Sprint races
    // Team: Circuit stations

    private static func buildFitnessScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        switch trainingType {
        case .solo:
            // Ladder Agility or Shuttle Runs
            if equipment.contains(.ladder) {
                // Agility Ladder: Player running through ladder
                elements.append(.ladder(at: FieldPosition(x: 0.5, y: 0.5), rotation: .degrees(0)))

                let playerPath = MovementPath(
                    waypoints: [
                        FieldPosition(x: 0.50, y: 0.82),
                        FieldPosition(x: 0.50, y: 0.70),
                        FieldPosition(x: 0.50, y: 0.58),
                        FieldPosition(x: 0.50, y: 0.46),
                        FieldPosition(x: 0.50, y: 0.34),
                        FieldPosition(x: 0.50, y: 0.22)
                    ],
                    duration: 3.0,
                    repeatBehavior: .pingPong,
                    pathType: .linear
                )
                elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.82), path: playerPath))
            } else {
                // Shuttle Runs: Sprint between cones
                elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.80)))  // Start
                elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.60)))  // 5m
                elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.40)))  // 10m
                elements.append(.cone(at: FieldPosition(x: 0.50, y: 0.20)))  // 15m

                let playerPath = MovementPath(
                    waypoints: [
                        FieldPosition(x: 0.50, y: 0.80),
                        FieldPosition(x: 0.50, y: 0.60),  // Touch cone
                        FieldPosition(x: 0.50, y: 0.80),  // Back
                        FieldPosition(x: 0.50, y: 0.40),  // Touch cone
                        FieldPosition(x: 0.50, y: 0.80),  // Back
                        FieldPosition(x: 0.50, y: 0.20),  // Touch cone
                        FieldPosition(x: 0.50, y: 0.80)   // Back
                    ],
                    duration: 5.0,
                    repeatBehavior: .loop,
                    pathType: .linear
                )
                elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.80), path: playerPath))
            }

        case .partner:
            // Sprint Races: Two players racing side by side
            elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.80)))  // Start line left
            elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.80)))  // Start line right
            elements.append(.cone(at: FieldPosition(x: 0.35, y: 0.20)))  // Finish left
            elements.append(.cone(at: FieldPosition(x: 0.65, y: 0.20)))  // Finish right

            // Player 1
            let player1Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.40, y: 0.78),
                    FieldPosition(x: 0.40, y: 0.22)
                ],
                duration: 2.5,
                repeatBehavior: .pingPong,
                pathType: .linear
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.40, y: 0.78), path: player1Path))

            // Player 2
            let player2Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.60, y: 0.78),
                    FieldPosition(x: 0.60, y: 0.22)
                ],
                duration: 2.5,
                repeatBehavior: .pingPong,
                pathType: .linear
            )
            elements.append(.player(.partner, at: FieldPosition(x: 0.60, y: 0.78), path: player2Path))

        case .team:
            // Circuit Stations: Multiple players at different stations
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
                    FieldPosition(x: 0.75, y: 0.25),
                    FieldPosition(x: 0.75, y: 0.70)
                ],
                duration: 2.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.teammate, at: FieldPosition(x: 0.75, y: 0.70), path: p3Path))
        }

        return TacticalScene(elements: elements, loopDuration: trainingType == .solo ? 5.0 : 2.5)
    }

    // MARK: - Goalkeeping Template
    // Solo: Distribution practice
    // Partner: Diving saves from shots
    // Team: Organizing defense on crosses

    private static func buildGoalkeepingScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal always present
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        switch trainingType {
        case .solo:
            // Distribution: GK practicing kicks and throws
            // GK movement and distribution
            let gkPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.22),
                    FieldPosition(x: 0.45, y: 0.25),  // Pick up ball
                    FieldPosition(x: 0.50, y: 0.22),  // Throw
                    FieldPosition(x: 0.55, y: 0.25),  // Pick up ball
                    FieldPosition(x: 0.50, y: 0.22)   // Kick
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.22), path: gkPath))

            // Ball being distributed to targets
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.25),
                    FieldPosition(x: 0.30, y: 0.70),  // Throw to target
                    FieldPosition(x: 0.50, y: 0.25),
                    FieldPosition(x: 0.70, y: 0.70),  // Kick to target
                    FieldPosition(x: 0.50, y: 0.25)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.25), path: ballPath))

            // Target cones for distribution
            elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.72)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.72)))

        case .partner:
            // Diving Save Practice: Shots to corners, GK dives
            // Goalkeeper diving left and right
            let gkPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.20),  // Set position
                    FieldPosition(x: 0.35, y: 0.22),  // Dive left
                    FieldPosition(x: 0.50, y: 0.20),  // Reset
                    FieldPosition(x: 0.65, y: 0.22),  // Dive right
                    FieldPosition(x: 0.50, y: 0.20)   // Reset
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
                    FieldPosition(x: 0.50, y: 0.52),  // At shooter
                    FieldPosition(x: 0.38, y: 0.12),  // Shot to left
                    FieldPosition(x: 0.50, y: 0.52),  // Reset
                    FieldPosition(x: 0.62, y: 0.12),  // Shot to right
                    FieldPosition(x: 0.50, y: 0.52)   // Reset
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.52), path: ballPath))

        case .team:
            // GK Communication: Organizing defense on crosses
            // Goalkeeper commanding
            let gkPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.18),
                    FieldPosition(x: 0.55, y: 0.16),  // Come for cross
                    FieldPosition(x: 0.50, y: 0.18)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.18), path: gkPath))

            // Defenders being organized
            elements.append(.player(.partner, at: FieldPosition(x: 0.35, y: 0.28)))
            elements.append(.player(.teammate, at: FieldPosition(x: 0.65, y: 0.28)))

            // Attacker in box
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.32)))

            // Crosser on wing
            elements.append(.player(.defender, at: FieldPosition(x: 0.85, y: 0.45)))

            // Cross coming in
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.82, y: 0.42),
                    FieldPosition(x: 0.55, y: 0.18),  // GK claims
                    FieldPosition(x: 0.82, y: 0.42)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.82, y: 0.42), path: ballPath))
        }

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }

    // MARK: - Defending Template
    // Solo: Clearance practice
    // Partner: 1v1 defending
    // Team: Defensive shape and pressing

    private static func buildDefendingScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        switch trainingType {
        case .solo:
            // Clearance Practice: Ball coming in, defender clears
            let playerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.40),
                    FieldPosition(x: 0.48, y: 0.38),  // Approach ball
                    FieldPosition(x: 0.50, y: 0.35),  // Clear
                    FieldPosition(x: 0.50, y: 0.40)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.40), path: playerPath))

            // Ball coming in and being cleared
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.70),  // Incoming
                    FieldPosition(x: 0.50, y: 0.38),  // At defender
                    FieldPosition(x: 0.55, y: 0.80),  // Cleared away
                    FieldPosition(x: 0.50, y: 0.70)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.70), path: ballPath))

            // Goal to protect
            elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        case .partner:
            // 1v1 Defending: Defender vs attacker
            // Grid markers
            elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.25)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.25)))
            elements.append(.cone(at: FieldPosition(x: 0.30, y: 0.75)))
            elements.append(.cone(at: FieldPosition(x: 0.70, y: 0.75)))

            // Defender jockeying
            let defenderPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.42),
                    FieldPosition(x: 0.45, y: 0.45),  // Shift with attacker
                    FieldPosition(x: 0.55, y: 0.40),
                    FieldPosition(x: 0.50, y: 0.42)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.50, y: 0.42), path: defenderPath))

            // Attacker trying to beat defender
            let attackerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.62),
                    FieldPosition(x: 0.42, y: 0.55),  // Try left
                    FieldPosition(x: 0.58, y: 0.52),  // Switch right
                    FieldPosition(x: 0.50, y: 0.62)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.62), path: attackerPath))

            // Ball with attacker
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.65),
                    FieldPosition(x: 0.42, y: 0.58),
                    FieldPosition(x: 0.58, y: 0.55),
                    FieldPosition(x: 0.50, y: 0.65)
                ],
                duration: 3.5,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.50, y: 0.65), path: ballPath))

            // Goal to protect
            elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))

        case .team:
            // Defensive Shape: Line of defenders shifting with ball
            // Ball moving side to side
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.25, y: 0.65),
                    FieldPosition(x: 0.75, y: 0.65),
                    FieldPosition(x: 0.25, y: 0.65)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.ball(at: FieldPosition(x: 0.25, y: 0.65), path: ballPath))

            // Attackers with ball
            elements.append(.player(.defender, at: FieldPosition(x: 0.25, y: 0.62)))
            elements.append(.player(.defender, at: FieldPosition(x: 0.50, y: 0.70)))
            elements.append(.player(.defender, at: FieldPosition(x: 0.75, y: 0.62)))

            // Defensive line shifting with ball
            let d1Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.30, y: 0.38),
                    FieldPosition(x: 0.55, y: 0.38),
                    FieldPosition(x: 0.30, y: 0.38)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.30, y: 0.38), path: d1Path))

            let d2Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.45, y: 0.40),
                    FieldPosition(x: 0.65, y: 0.40),
                    FieldPosition(x: 0.45, y: 0.40)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.partner, at: FieldPosition(x: 0.45, y: 0.40), path: d2Path))

            let d3Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.55, y: 0.38),
                    FieldPosition(x: 0.75, y: 0.38),
                    FieldPosition(x: 0.55, y: 0.38)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.teammate, at: FieldPosition(x: 0.55, y: 0.38), path: d3Path))

            // Goal
            elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.12), size: .full))
        }

        return TacticalScene(elements: elements, loopDuration: trainingType == .solo ? 3.0 : 4.0, showHalfField: trainingType != .solo)
    }

    // MARK: - Set Pieces Template
    // Solo: Free kick / penalty practice
    // Partner: Throw-in routines
    // Team: Corner routines with movement

    private static func buildSetPiecesScene(
        trainingType: TrainingType,
        equipment: [Equipment]
    ) -> TacticalScene {
        var elements: [FieldElement] = []

        // Goal
        elements.append(.goal(at: FieldPosition(x: 0.5, y: 0.10), size: .full))

        switch trainingType {
        case .solo:
            // Free Kick or Penalty Practice
            // Goalkeeper
            let gkPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.50, y: 0.17),
                    FieldPosition(x: 0.45, y: 0.17),  // Dive
                    FieldPosition(x: 0.50, y: 0.17)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17), path: gkPath))

            // Free kick wall (mannequins)
            elements.append(.mannequin(at: FieldPosition(x: 0.42, y: 0.38)))
            elements.append(.mannequin(at: FieldPosition(x: 0.50, y: 0.38)))
            elements.append(.mannequin(at: FieldPosition(x: 0.58, y: 0.38)))

            // Kicker
            let kickerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.42, y: 0.60),  // Starting position
                    FieldPosition(x: 0.45, y: 0.55),  // Run up
                    FieldPosition(x: 0.48, y: 0.50),  // Strike
                    FieldPosition(x: 0.42, y: 0.60)   // Reset
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.42, y: 0.60), path: kickerPath))

            // Ball curves around wall
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.48, y: 0.52),  // At spot
                    FieldPosition(x: 0.48, y: 0.52),  // Pause
                    FieldPosition(x: 0.62, y: 0.30),  // Curve around wall
                    FieldPosition(x: 0.58, y: 0.12),  // Into goal!
                    FieldPosition(x: 0.48, y: 0.52)   // Reset
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.48, y: 0.52), path: ballPath))

        case .partner:
            // Throw-In Routines
            // No goal needed for this, remove it
            // Thrower on sideline
            let throwerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.05, y: 0.50),
                    FieldPosition(x: 0.05, y: 0.48),  // Wind up
                    FieldPosition(x: 0.05, y: 0.50)   // Throw
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.05, y: 0.50), path: throwerPath))

            // Receiver making run
            let receiverPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.30, y: 0.50),
                    FieldPosition(x: 0.25, y: 0.45),  // Check away
                    FieldPosition(x: 0.20, y: 0.52),  // Come short
                    FieldPosition(x: 0.30, y: 0.50)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.partner, at: FieldPosition(x: 0.30, y: 0.50), path: receiverPath))

            // Ball trajectory
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.08, y: 0.50),
                    FieldPosition(x: 0.20, y: 0.50),  // Short throw
                    FieldPosition(x: 0.08, y: 0.50)
                ],
                duration: 3.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.08, y: 0.50), path: ballPath))

            // Sideline markers
            elements.append(.cone(at: FieldPosition(x: 0.05, y: 0.40)))
            elements.append(.cone(at: FieldPosition(x: 0.05, y: 0.60)))

            return TacticalScene(elements: elements, loopDuration: 3.0, showHalfField: false)

        case .team:
            // Corner Kick Routine
            // Goalkeeper
            elements.append(.player(.goalkeeper, at: FieldPosition(x: 0.50, y: 0.17)))

            // Corner taker
            let cornerTakerPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.95, y: 0.05),
                    FieldPosition(x: 0.92, y: 0.08),  // Run up
                    FieldPosition(x: 0.95, y: 0.05)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.player(.primary, at: FieldPosition(x: 0.95, y: 0.05), path: cornerTakerPath))

            // Attackers making runs
            let att1Path = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.55, y: 0.45),
                    FieldPosition(x: 0.52, y: 0.28),  // Near post run
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
                    FieldPosition(x: 0.38, y: 0.25),  // Far post run
                    FieldPosition(x: 0.40, y: 0.50)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .linear
            )
            elements.append(.player(.teammate, at: FieldPosition(x: 0.40, y: 0.50), path: att2Path))

            // Defender marking
            elements.append(.player(.defender, at: FieldPosition(x: 0.48, y: 0.30)))
            elements.append(.player(.defender, at: FieldPosition(x: 0.42, y: 0.32)))

            // Ball - corner delivery
            let ballPath = MovementPath(
                waypoints: [
                    FieldPosition(x: 0.92, y: 0.05),  // Corner spot
                    FieldPosition(x: 0.92, y: 0.05),  // Pause
                    FieldPosition(x: 0.52, y: 0.24),  // Near post delivery
                    FieldPosition(x: 0.50, y: 0.12),  // Header to goal!
                    FieldPosition(x: 0.92, y: 0.05)
                ],
                duration: 4.0,
                repeatBehavior: .loop,
                pathType: .curved
            )
            elements.append(.ball(at: FieldPosition(x: 0.92, y: 0.05), path: ballPath))
        }

        return TacticalScene(elements: elements, loopDuration: 4.0, showHalfField: true)
    }
}
