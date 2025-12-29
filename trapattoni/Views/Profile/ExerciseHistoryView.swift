import SwiftUI
import SwiftData

// MARK: - Helper Function

private func colorFor(category: ExerciseCategory) -> Color {
    switch category {
    case .dribbling: return .blue
    case .passing: return .green
    case .shooting: return .orange
    case .firstTouch: return .purple
    case .fitnessConditioning: return .red
    case .goalkeeping: return .yellow
    case .defending: return .gray
    case .setPieces: return .cyan
    }
}

struct ExerciseHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExerciseRating.ratedAt, order: .reverse)
    private var allRatings: [ExerciseRating]
    @Query private var exercises: [Exercise]

    @State private var selectedCategory: ExerciseCategory?
    @State private var sortOption: SortOption = .frequency
    @State private var searchText: String = ""

    enum SortOption: String, CaseIterable {
        case frequency = "Most Practiced"
        case recent = "Most Recent"
        case rating = "Highest Rated"
        case name = "Name"
    }

    private var exerciseStats: [ExerciseStats] {
        // Group ratings by exercise
        let grouped = Dictionary(grouping: allRatings, by: \.exerciseId)

        var stats: [ExerciseStats] = []

        for (exerciseId, ratings) in grouped {
            let exerciseName = ratings.first?.exerciseName ?? "Unknown"
            let category = ratings.first?.exerciseCategory ?? .dribbling

            // Skip if filtered by category
            if let selectedCategory, category != selectedCategory {
                continue
            }

            // Skip if search doesn't match
            if !searchText.isEmpty && !exerciseName.localizedCaseInsensitiveContains(searchText) {
                continue
            }

            let avgRating = Double(ratings.reduce(0) { $0 + $1.rating }) / Double(ratings.count)
            let lastPracticed = ratings.first?.ratedAt ?? Date.distantPast

            stats.append(ExerciseStats(
                exerciseId: exerciseId,
                name: exerciseName,
                category: category,
                practiceCount: ratings.count,
                averageRating: avgRating,
                lastPracticed: lastPracticed,
                ratings: ratings.sorted { $0.ratedAt > $1.ratedAt }
            ))
        }

        // Sort based on option
        switch sortOption {
        case .frequency:
            return stats.sorted { $0.practiceCount > $1.practiceCount }
        case .recent:
            return stats.sorted { $0.lastPracticed > $1.lastPracticed }
        case .rating:
            return stats.sorted { $0.averageRating > $1.averageRating }
        case .name:
            return stats.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        List {
            // Filter Section
            Section {
                Picker("Sort By", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(categoriesWithData, id: \.self) { category in
                            CategoryFilterChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Stats Summary
            if !exerciseStats.isEmpty {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(exerciseStats.count)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("\(totalPractices)")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Total Practices")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Exercise List
            if exerciseStats.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Exercise History",
                        systemImage: "figure.run",
                        description: Text("Complete training sessions to see your exercise history")
                    )
                }
            } else {
                Section("Exercises") {
                    ForEach(exerciseStats) { stat in
                        NavigationLink {
                            ExerciseDetailHistoryView(stats: stat)
                        } label: {
                            ExerciseHistoryRow(stats: stat)
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise History")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $searchText, prompt: "Search exercises")
    }

    private var categoriesWithData: [ExerciseCategory] {
        let categories = Set(allRatings.map { $0.exerciseCategory })
        return ExerciseCategory.allCases.filter { categories.contains($0) }
    }

    private var totalPractices: Int {
        exerciseStats.reduce(0) { $0 + $1.practiceCount }
    }
}

// MARK: - Exercise Stats Model

struct ExerciseStats: Identifiable {
    let exerciseId: UUID
    let name: String
    let category: ExerciseCategory
    let practiceCount: Int
    let averageRating: Double
    let lastPracticed: Date
    let ratings: [ExerciseRating]

    var id: UUID { exerciseId }

    var lastPracticedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastPracticed, relativeTo: Date())
    }
}

// MARK: - Exercise History Row

struct ExerciseHistoryRow: View {
    let stats: ExerciseStats

    private var categoryColor: Color {
        colorFor(category: stats.category)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: stats.category.iconName)
                .font(.title3)
                .foregroundStyle(categoryColor)
                .frame(width: 36, height: 36)
                .background(categoryColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(stats.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(stats.practiceCount)x", systemImage: "repeat")
                    Text(stats.lastPracticedFormatted)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Rating
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", stats.averageRating))
                }
                .font(.subheadline)

                Text("avg")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Detail History View

struct ExerciseDetailHistoryView: View {
    let stats: ExerciseStats

    @State private var selectedTimeRange: TimeRange = .all

    private var categoryColor: Color {
        colorFor(category: stats.category)
    }

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    private var filteredRatings: [ExerciseRating] {
        let now = Date()
        let calendar = Calendar.current

        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return stats.ratings.filter { $0.ratedAt >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return stats.ratings.filter { $0.ratedAt >= monthAgo }
        case .all:
            return stats.ratings
        }
    }

    private var averageForRange: Double {
        guard !filteredRatings.isEmpty else { return 0 }
        return Double(filteredRatings.reduce(0) { $0 + $1.rating }) / Double(filteredRatings.count)
    }

    var body: some View {
        List {
            // Header
            Section {
                VStack(spacing: 16) {
                    Image(systemName: stats.category.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(categoryColor)
                        .frame(width: 60, height: 60)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(Circle())

                    VStack(spacing: 4) {
                        Text(stats.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(stats.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Time Range Picker
            Section {
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            // Stats for Range
            Section("Statistics") {
                HStack {
                    StatItem(
                        title: "Practices",
                        value: "\(filteredRatings.count)",
                        icon: "repeat"
                    )

                    Divider()

                    StatItem(
                        title: "Avg Rating",
                        value: String(format: "%.1f", averageForRange),
                        icon: "star.fill"
                    )

                    Divider()

                    StatItem(
                        title: "Best",
                        value: "\(filteredRatings.map(\.rating).max() ?? 0)",
                        icon: "trophy.fill"
                    )
                }
                .padding(.vertical, 8)
            }

            // Progress Chart (Simple visualization)
            if filteredRatings.count > 1 {
                Section("Progress") {
                    RatingProgressChart(ratings: filteredRatings)
                        .frame(height: 120)
                }
            }

            // History
            Section("Practice History") {
                if filteredRatings.isEmpty {
                    Text("No practices in this time range")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredRatings) { rating in
                        RatingHistoryRow(rating: rating)
                    }
                }
            }
        }
        .navigationTitle("Exercise Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Rating History Row

struct RatingHistoryRow: View {
    let rating: ExerciseRating

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(rating.ratedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)

                if !rating.notes.isEmpty {
                    Text(rating.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= rating.rating ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(star <= rating.rating ? .yellow : .secondary.opacity(0.3))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Rating Progress Chart

struct RatingProgressChart: View {
    let ratings: [ExerciseRating]

    private var sortedRatings: [ExerciseRating] {
        ratings.sorted { $0.ratedAt < $1.ratedAt }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = sortedRatings.count
            let spacing = count > 1 ? width / CGFloat(count - 1) : 0

            ZStack {
                // Grid lines
                ForEach(1...5, id: \.self) { line in
                    let y = height - (CGFloat(line) / 5.0 * height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4]))
                }

                // Line chart
                if count > 1 {
                    Path { path in
                        for (index, rating) in sortedRatings.enumerated() {
                            let x = CGFloat(index) * spacing
                            let y = height - (CGFloat(rating.rating) / 5.0 * height)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Points
                    ForEach(Array(sortedRatings.enumerated()), id: \.offset) { index, rating in
                        let x = CGFloat(index) * spacing
                        let y = height - (CGFloat(rating.rating) / 5.0 * height)

                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseHistoryView()
    }
    .modelContainer(for: [ExerciseRating.self, Exercise.self], inMemory: true)
}
