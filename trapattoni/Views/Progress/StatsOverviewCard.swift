import SwiftUI

struct StatsOverviewCard: View {
    let stats: StatsService.OverviewStats

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("progress.overview".localized)
                    .font(.headline)
                Spacer()
            }

            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItemView(
                    title: "progress.totalSessions".localized,
                    value: "\(stats.totalSessions)",
                    icon: "figure.run",
                    color: .blue
                )

                StatItemView(
                    title: "progress.timeTrained".localized,
                    value: formatDuration(stats.totalTimeMinutes),
                    icon: "clock",
                    color: .purple
                )

                StatItemView(
                    title: "progress.currentStreak".localized,
                    value: "\(stats.currentStreak) \(stats.currentStreak == 1 ? "progress.day".localized : "progress.days".localized)",
                    icon: "flame.fill",
                    color: stats.currentStreak > 0 ? .orange : .gray
                )

                StatItemView(
                    title: "progress.thisWeek".localized,
                    value: "\(stats.thisWeekSessions) \(stats.thisWeekSessions == 1 ? "progress.session".localized : "progress.sessionsCount".localized)",
                    icon: "calendar",
                    color: .green
                )
            }

            // Additional stats row
            HStack(spacing: 16) {
                MiniStatView(
                    title: "progress.longestStreak".localized,
                    value: "\(stats.longestStreak) \("progress.days".localized)",
                    icon: "trophy"
                )

                MiniStatView(
                    title: "progress.avgSession".localized,
                    value: "\(stats.averageSessionLength) \("time.min".localized)",
                    icon: "timer"
                )

                MiniStatView(
                    title: "history.exercises".localized,
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
            return "\(minutes) \("time.min".localized)"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours)\("time.hours".localized)"
        }
        return "\(hours)\("time.hours".localized) \(mins)\("time.minutes".localized)"
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
