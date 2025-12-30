import SwiftUI

struct ActivePlanCard: View {
    let plan: TrainingPlan

    var body: some View {
        HStack(spacing: 12) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: plan.progressPercentage)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(plan.progressPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.localizedName)
                    .font(.headline)
                    .lineLimit(1)

                Text("Week \(plan.currentWeek) of \(plan.durationWeeks)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label("\(plan.completedSessions) done", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Label("\(plan.totalSessions - plan.completedSessions) left", systemImage: "circle")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }

            Spacer()

            // Continue indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .fontWeight(.semibold)
            Text(label)
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

#Preview {
    ActivePlanCard(plan: {
        let plan = TrainingPlan(
            name: "Beginner Fundamentals",
            description: "4 week program",
            durationWeeks: 4,
            targetSessionsPerWeek: 3
        )
        plan.start()
        return plan
    }())
    .padding()
}
