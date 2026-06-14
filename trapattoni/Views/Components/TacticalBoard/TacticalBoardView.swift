import SwiftUI

/// Animated tactical board showing exercise visualization
struct TacticalBoardView: View {
    let exercise: Exercise
    let isCompact: Bool

    // Scene geometry is static per exercise, so everything that doesn't
    // depend on the current frame time is computed once here instead of
    // inside the 60fps Canvas closure.
    private let scene: TacticalScene
    private let animationSpeed: AnimationSpeed
    private let drawList: [(element: FieldElement, playerNumber: Int?)]
    private let trails: [(points: [FieldPosition], color: Color, isDashed: Bool)]

    @State private var startTime: Date = Date()

    init(exercise: Exercise, isCompact: Bool = false) {
        self.exercise = exercise
        self.isCompact = isCompact

        let scene = ExerciseAnimationBuilder.buildScene(for: exercise)
        self.scene = scene
        self.animationSpeed = AnimationSpeed(from: exercise.skillLevel)

        // Sort elements: equipment first, then players, then ball on top
        let sorted = scene.elements.sorted {
            Self.elementDrawOrder($0.type) < Self.elementDrawOrder($1.type)
        }

        // Number players per role (1, 2, 3...) in draw order
        var playerNumbers: [String: Int] = [:]
        self.drawList = sorted.map { element in
            guard case .player(let role) = element.type else {
                return (element, nil)
            }
            let number = (playerNumbers[role.rawValue] ?? 0) + 1
            playerNumbers[role.rawValue] = number
            return (element, number)
        }

        // Trails follow the actual motion (spline samples for curved paths)
        self.trails = scene.elements.compactMap { element in
            guard let path = element.movementPath, path.waypoints.count >= 2 else { return nil }

            switch element.type {
            case .player(let role):
                return (AnimationEngine.trailPoints(for: path), role.color, false)
            case .ball:
                return (AnimationEngine.trailPoints(for: path), .white, true)
            default:
                return nil // Don't draw trails for equipment
            }
        }
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
                for trail in trails {
                    drawPathTrail(
                        points: trail.points,
                        context: context,
                        size: size,
                        color: trail.color,
                        isDashed: trail.isDashed
                    )
                }

                // Draw animated elements
                for (element, playerNumber) in drawList {
                    let position = AnimationEngine.currentPosition(
                        for: element,
                        at: elapsedTime,
                        speed: animationSpeed
                    )
                    let direction = AnimationEngine.direction(
                        for: element,
                        at: elapsedTime,
                        speed: animationSpeed
                    )

                    ElementRenderer.drawElement(
                        element,
                        at: position,
                        direction: direction,
                        in: context,
                        size: size,
                        scale: scale,
                        playerNumber: playerNumber,
                        time: elapsedTime
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
    private static func elementDrawOrder(_ type: FieldElementType) -> Int {
        switch type {
        case .goal: return 0
        case .wall, .rebounder: return 1
        case .ladder, .hurdle, .pole: return 2
        case .cone, .mannequin: return 3
        case .player: return 4
        case .ball: return 5
        }
    }

    /// Draw a faded trail through the sampled path points
    private func drawPathTrail(
        points: [FieldPosition],
        context: GraphicsContext,
        size: CGSize,
        color: Color,
        isDashed: Bool
    ) {
        guard points.count >= 2 else { return }

        var trailPath = Path()
        trailPath.move(to: points[0].toPoint(in: size))

        for i in 1..<points.count {
            trailPath.addLine(to: points[i].toPoint(in: size))
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
