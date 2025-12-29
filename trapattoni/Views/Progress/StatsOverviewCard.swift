import SwiftUI

struct StatsOverviewCard: View {
    let stats: StatsService.OverviewStats

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Overview")
                    .font(.headline)
                Spacer()
            }

            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItemView(
                    title: "Total Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "figure.run",
                    color: .blue
                )

                StatItemView(
                    title: "Time Trained",
                    value: formatDuration(stats.totalTimeMinutes),
                    icon: "clock",
                    color: .purple
                )

                StatItemView(
                    title: "Current Streak",
                    value: "\(stats.currentStreak) day\(stats.currentStreak == 1 ? "" : "s")",
                    icon: "flame.fill",
                    color: stats.currentStreak > 0 ? .orange : .gray
                )

                StatItemView(
                    title: "This Week",
                    value: "\(stats.thisWeekSessions) session\(stats.thisWeekSessions == 1 ? "" : "s")",
                    icon: "calendar",
                    color: .green
                )
            }

            // Additional stats row
            HStack(spacing: 16) {
                MiniStatView(
                    title: "Longest Streak",
                    value: "\(stats.longestStreak) days",
                    icon: "trophy"
                )

                MiniStatView(
                    title: "Avg. Session",
                    value: "\(stats.averageSessionLength) min",
                    icon: "timer"
                )

                MiniStatView(
                    title: "Exercises",
                    value: "\(stats.totalExercises)",
                    icon: "checkmark.circle"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(mins)m"
    }
}

// MARK: - Stat Item View

struct StatItemView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Mini Stat View

struct MiniStatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsOverviewCard(stats: StatsService.OverviewStats(
        totalSessions: 24,
        totalTimeMinutes: 480,
        totalExercises: 156,
        currentStreak: 5,
        longestStreak: 12,
        thisWeekSessions: 3,
        thisMonthSessions: 10,
        averageSessionLength: 20,
        favoriteCategory: .dribbling,
        totalGymSessions: 5,
        totalGames: 3,
        totalCardio: 2,
        totalRecovery: 4,
        thisWeekActivities: 4
    ))
    .padding()
}
