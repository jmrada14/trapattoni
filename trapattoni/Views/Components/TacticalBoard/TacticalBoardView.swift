import SwiftUI

/// Animated tactical board showing exercise visualization
struct TacticalBoardView: View {
    let exercise: Exercise
    var isCompact: Bool = false

    @State private var startTime: Date = Date()

    private var scene: TacticalScene {
        ExerciseAnimationBuilder.buildScene(for: exercise)
    }

    private var animationSpeed: AnimationSpeed {
        AnimationSpeed(from: exercise.skillLevel)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let elapsedTime = timeline.date.timeIntervalSince(startTime)
                let scale: CGFloat = isCompact ? 0.8 : 1.0

                // Draw field background
                FieldRenderer.drawField(
                    context: context,
                    size: size,
                    halfField: scene.showHalfField
                )

                // Draw movement trails first (so they appear behind elements)
                drawMovementTrails(
                    scene: scene,
                    elapsedTime: elapsedTime,
                    context: context,
                    size: size
                )

                // Draw animated elements
                let animatedElements = AnimationEngine.animatedElements(
                    for: scene,
                    at: elapsedTime,
                    speed: animationSpeed
                )

                // Sort elements: equipment first, then players, then ball on top
                let sortedElements = animatedElements.sorted { e1, e2 in
                    elementDrawOrder(e1.element.type) < elementDrawOrder(e2.element.type)
                }

                // Track player numbers by role
                var playerNumbers: [String: Int] = [:]

                for (element, position, direction) in sortedElements {
                    var playerNumber: Int? = nil

                    // Assign numbers to players
                    if case .player(let role) = element.type {
                        let key = role.rawValue
                        let num = (playerNumbers[key] ?? 0) + 1
                        playerNumbers[key] = num
                        playerNumber = num
                    }

                    ElementRenderer.drawElement(
                        element,
                        at: position,
                        direction: direction,
                        in: context,
                        size: size,
                        scale: scale,
                        playerNumber: playerNumber
                    )
                }
            }
        }
        .aspectRatio(isCompact ? 4.0 / 3.0 : 16.0 / 10.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 8 : 12))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .onAppear {
            startTime = Date()
        }
    }

    // MARK: - Drawing Helpers

    /// Determine draw order (lower = drawn first / behind)
    private func elementDrawOrder(_ type: FieldElementType) -> Int {
        switch type {
        case .goal: return 0
        case .wall, .rebounder: return 1
        case .ladder, .hurdle, .pole: return 2
        case .cone, .mannequin: return 3
        case .player: return 4
        case .ball: return 5
        }
    }

    /// Draw faded movement trails for elements with paths
    private func drawMovementTrails(
        scene: TacticalScene,
        elapsedTime: TimeInterval,
        context: GraphicsContext,
        size: CGSize
    ) {
        for element in scene.elements {
            guard let movementPath = element.movementPath, movementPath.waypoints.count >= 2 else { continue }

            // Determine trail color based on element type
            let trailColor: Color
            var isDashed: Bool = false

            switch element.type {
            case .player(let role):
                trailColor = role.color
            case .ball:
                trailColor = .white
                isDashed = true
            default:
                continue // Don't draw trails for equipment
            }

            // Draw the full movement path as a faded trail
            drawPathTrail(
                waypoints: movementPath.waypoints,
                context: context,
                size: size,
                color: trailColor,
                isDashed: isDashed
            )
        }
    }

    /// Draw a path trail connecting waypoints
    private func drawPathTrail(
        waypoints: [FieldPosition],
        context: GraphicsContext,
        size: CGSize,
        color: Color,
        isDashed: Bool
    ) {
        guard waypoints.count >= 2 else { return }

        var trailPath = Path()
        let firstPoint = waypoints[0].toPoint(in: size)
        trailPath.move(to: firstPoint)

        for i in 1..<waypoints.count {
            let point = waypoints[i].toPoint(in: size)
            trailPath.addLine(to: point)
        }

        let style = isDashed
            ? StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [4, 4])
            : StrokeStyle(lineWidth: 1.5, lineCap: .round)

        context.stroke(trailPath, with: .color(color.opacity(0.25)), style: style)
    }
}

// MARK: - Tactical Board Section

/// A styled section containing the tactical board for use in detail views
struct TacticalBoardSection: View {
    let exercise: Exercise
    var isCompact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !isCompact {
                HStack {
                    Image(systemName: "sportscourt")
                        .foregroundStyle(.green)
                    Text("Exercise Visualization")
                        .font(.headline)
                }
            }

            TacticalBoardView(exercise: exercise, isCompact: isCompact)
                .frame(height: isCompact ? 120 : 200)
        }
    }
}

// MARK: - Preview

#Preview("Dribbling - Solo") {
    @Previewable @State var exercise = Exercise(
        name: "Cone Weave Dribbling",
        description: "Navigate through cones",
        category: .dribbling,
        trainingType: .solo,
        skillLevel: .beginner,
        duration: .short,
        spaceRequired: .small
    )

    TacticalBoardView(exercise: exercise)
        .padding()
        .frame(height: 250)
}

#Preview("Passing - Partner") {
    @Previewable @State var exercise = Exercise(
        name: "Wall Passing",
        description: "Pass against a wall",
        category: .passing,
        trainingType: .partner,
        skillLevel: .intermediate,
        duration: .medium,
        spaceRequired: .medium
    )

    TacticalBoardView(exercise: exercise)
        .padding()
        .frame(height: 250)
}

#Preview("Shooting - Solo") {
    @Previewable @State var exercise = Exercise(
        name: "Shooting Practice",
        description: "Shoot on goal",
        category: .shooting,
        trainingType: .solo,
        skillLevel: .intermediate,
        duration: .medium,
        spaceRequired: .large
    )

    TacticalBoardView(exercise: exercise)
        .padding()
        .frame(height: 250)
}

#Preview("Compact Mode") {
    @Previewable @State var exercise = Exercise(
        name: "Quick Drill",
        description: "Fast drill",
        category: .fitnessConditioning,
        trainingType: .solo,
        skillLevel: .advanced,
        duration: .short,
        spaceRequired: .small
    )

    TacticalBoardSection(exercise: exercise, isCompact: true)
        .padding()
}
