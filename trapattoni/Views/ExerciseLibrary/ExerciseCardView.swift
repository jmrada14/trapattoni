import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row with name and indicators
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if exercise.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if exercise.isUserCreated {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            // Description
            Text(exercise.exerciseDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Metadata row
            HStack(spacing: 12) {
                SkillLevelBadge(level: exercise.skillLevel)

                Label {
                    Text(exercise.trainingType.rawValue)
                } icon: {
                    Image(systemName: exercise.trainingType.iconName)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Label {
                    Text(durationShortText)
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            // Equipment badges
            if !exercise.equipment.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(exercise.equipment) { item in
                            EquipmentBadgeView(equipment: item, style: .large)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var durationShortText: String {
        switch exercise.duration {
        case .short: return "5-10m"
        case .medium: return "10-20m"
        case .long: return "20m+"
        }
    }
}

#Preview {
    List {
        ExerciseCardView(exercise: Exercise(
            name: "Cone Weave Dribbling",
            description: "Navigate through a line of cones using close ball control, alternating feet with each touch.",
            category: .dribbling,
            trainingType: .solo,
            skillLevel: .beginner,
            duration: .short,
            spaceRequired: .small,
            equipment: [.ball, .cones]
        ))

        ExerciseCardView(exercise: Exercise(
            name: "Advanced Free Kick Practice",
            description: "Master the art of bending free kicks around the wall and into the corners.",
            category: .setPieces,
            trainingType: .solo,
            skillLevel: .advanced,
            duration: .medium,
            spaceRequired: .large,
            equipment: [.ball, .goal, .mannequin],
            isUserCreated: true
        ))
    }
}
