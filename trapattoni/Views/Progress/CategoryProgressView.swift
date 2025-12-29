import SwiftUI
import Charts

struct CategoryProgressView: View {
    let progress: [StatsService.CategoryProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Skill Progress by Category")
                .font(.headline)

            // Bar Chart
            Chart(progress) { item in
                BarMark(
                    x: .value("Rating", item.averageRating),
                    y: .value("Category", item.category.rawValue)
                )
                .foregroundStyle(colorFor(item.category))
                .cornerRadius(4)
            }
            .chartXScale(domain: 0...5)
            .chartXAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)★")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: CGFloat(progress.count * 40 + 20))

            // Category details
            VStack(spacing: 8) {
                ForEach(progress) { item in
                    CategoryProgressRow(progress: item)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func colorFor(_ category: ExerciseCategory) -> Color {
        switch category {
        case .dribbling: return .blue
        case .passing: return .green
        case .shooting: return .red
        case .firstTouch: return .purple
        case .fitnessConditioning: return .orange
        case .goalkeeping: return .yellow
        case .defending: return .indigo
        case .setPieces: return .pink
        }
    }
}

// MARK: - Category Progress Row

struct CategoryProgressRow: View {
    let progress: StatsService.CategoryProgress

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: progress.category, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(progress.category.rawValue)
                    .font(.subheadline)

                Text("\(progress.totalRatings) rating\(progress.totalRatings == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Rating display
            HStack(spacing: 4) {
                Text(String(format: "%.1f", progress.averageRating))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }

            // Trend indicator
            TrendIndicator(trend: progress.recentTrend)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trend Indicator

struct TrendIndicator: View {
    let trend: StatsService.CategoryProgress.Trend

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: trend.iconName)
                .font(.caption)

            Text(trend.rawValue)
                .font(.caption2)
        }
        .foregroundStyle(colorFor(trend))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(colorFor(trend).opacity(0.15))
        .clipShape(Capsule())
    }

    private func colorFor(_ trend: StatsService.CategoryProgress.Trend) -> Color {
        switch trend {
        case .improving: return .green
        case .stable: return .secondary
        case .declining: return .red
        }
    }
}

#Preview {
    CategoryProgressView(progress: [
        StatsService.CategoryProgress(
            category: .dribbling,
            averageRating: 4.2,
            totalRatings: 15,
            recentTrend: .improving
        ),
        StatsService.CategoryProgress(
            category: .passing,
            averageRating: 3.8,
            totalRatings: 12,
            recentTrend: .stable
        ),
        StatsService.CategoryProgress(
            category: .shooting,
            averageRating: 3.2,
            totalRatings: 8,
            recentTrend: .declining
        )
    ])
    .padding()
}
