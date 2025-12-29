import Foundation
import SwiftData

struct StatsService {
    // MARK: - Stats Models

    struct OverviewStats {
        var totalSessions: Int
        var totalTimeMinutes: Int
        var totalExercises: Int
        var currentStreak: Int
        var longestStreak: Int
        var thisWeekSessions: Int
        var thisMonthSessions: Int
        var averageSessionLength: Int
        var favoriteCategory: ExerciseCategory?

        // Activity breakdown
        var totalGymSessions: Int
        var totalGames: Int
        var totalCardio: Int
        var totalRecovery: Int
        var thisWeekActivities: Int
    }

    struct ActivityStats {
        var type: ActivityType
        var totalCount: Int
        var totalMinutes: Int
        var thisWeekCount: Int
        var thisMonthCount: Int
    }

    struct CategoryProgress: Identifiable {
        var id: String { category.rawValue }
        var category: ExerciseCategory
        var averageRating: Double
        var totalRatings: Int
        var recentTrend: Trend

        enum Trend: String {
            case improving = "Improving"
            case stable = "Stable"
            case declining = "Declining"

            var iconName: String {
                switch self {
                case .improving: return "arrow.up.right"
                case .stable: return "arrow.right"
                case .declining: return "arrow.down.right"
                }
            }
        }
    }

    struct WeeklyStats {
        var weekStart: Date
        var sessionsCompleted: Int
        var totalMinutes: Int
        var exercisesCompleted: Int
    }

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    func calculateOverviewStats() throws -> OverviewStats {
        let logs = try fetchCompletedLogs()
        let activities = try fetchCompletedActivities()

        let totalTime = logs.reduce(0) { $0 + $1.actualDurationSeconds }
        let totalExercises = logs.reduce(0) { $0 + $1.exercisesCompleted }
        let streaks = calculateStreaks(from: logs)

        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let thisWeek = logs.filter {
            ($0.completedAt ?? Date.distantPast) >= startOfWeek
        }.count

        let thisMonth = logs.filter {
            ($0.completedAt ?? Date.distantPast) >= startOfMonth
        }.count

        let avgLength = logs.isEmpty ? 0 : totalTime / logs.count / 60

        let favoriteCategory = try findFavoriteCategory()

        // Calculate activity stats
        let gymActivities = activities.filter { $0.activityType == .gym }
        let gameActivities = activities.filter { $0.activityType == .game }
        let cardioActivities = activities.filter { $0.activityType == .cardio }
        let recoveryActivities = activities.filter { $0.activityType == .recovery }

        let thisWeekActivities = activities.filter {
            ($0.completedAt ?? Date.distantPast) >= startOfWeek
        }.count

        return OverviewStats(
            totalSessions: logs.count,
            totalTimeMinutes: totalTime / 60,
            totalExercises: totalExercises,
            currentStreak: streaks.current,
            longestStreak: streaks.longest,
            thisWeekSessions: thisWeek,
            thisMonthSessions: thisMonth,
            averageSessionLength: avgLength,
            favoriteCategory: favoriteCategory,
            totalGymSessions: gymActivities.count,
            totalGames: gameActivities.count,
            totalCardio: cardioActivities.count,
            totalRecovery: recoveryActivities.count,
            thisWeekActivities: thisWeekActivities
        )
    }

    func calculateCategoryProgress() throws -> [CategoryProgress] {
        let ratings = try fetchAllRatings()
        let grouped = Dictionary(grouping: ratings, by: \.exerciseCategory)

        return ExerciseCategory.allCases.compactMap { category -> CategoryProgress? in
            guard let categoryRatings = grouped[category], !categoryRatings.isEmpty else {
                return nil
            }

            let avgRating = Double(categoryRatings.reduce(0) { $0 + $1.rating }) / Double(categoryRatings.count)
            let trend = calculateTrend(for: categoryRatings)

            return CategoryProgress(
                category: category,
                averageRating: avgRating,
                totalRatings: categoryRatings.count,
                recentTrend: trend
            )
        }
    }

    func getTrainingDays(for month: Date? = nil) throws -> Set<DateComponents> {
        let logs = try fetchCompletedLogs()
        let calendar = Calendar.current

        var components = logs.compactMap { log -> DateComponents? in
            guard let date = log.completedAt else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: date)
        }

        if let month = month {
            let targetMonth = calendar.component(.month, from: month)
            let targetYear = calendar.component(.year, from: month)
            components = components.filter {
                $0.month == targetMonth && $0.year == targetYear
            }
        }

        return Set(components)
    }

    func getWeeklyStats(weeks: Int = 4) throws -> [WeeklyStats] {
        let logs = try fetchCompletedLogs()
        let calendar = Calendar.current
        let now = Date()

        return (0..<weeks).compactMap { weekOffset -> WeeklyStats? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
                return nil
            }

            let weekLogs = logs.filter { log in
                guard let completedAt = log.completedAt else { return false }
                return completedAt >= weekInterval.start && completedAt < weekInterval.end
            }

            return WeeklyStats(
                weekStart: weekInterval.start,
                sessionsCompleted: weekLogs.count,
                totalMinutes: weekLogs.reduce(0) { $0 + $1.actualDurationSeconds } / 60,
                exercisesCompleted: weekLogs.reduce(0) { $0 + $1.exercisesCompleted }
            )
        }.reversed()
    }

    func getRecentLogs(limit: Int = 10) throws -> [SessionLog] {
        var descriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func calculateActivityStats() throws -> [ActivityStats] {
        let activities = try fetchCompletedActivities()
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now

        return ActivityType.allCases.map { type in
            let typeActivities = activities.filter { $0.activityType == type }
            let thisWeek = typeActivities.filter {
                ($0.completedAt ?? Date.distantPast) >= startOfWeek
            }
            let thisMonth = typeActivities.filter {
                ($0.completedAt ?? Date.distantPast) >= startOfMonth
            }
            let totalMinutes = typeActivities.reduce(0) { $0 + $1.durationMinutes }

            return ActivityStats(
                type: type,
                totalCount: typeActivities.count,
                totalMinutes: totalMinutes,
                thisWeekCount: thisWeek.count,
                thisMonthCount: thisMonth.count
            )
        }
    }

    func getActivityDays(for month: Date? = nil) throws -> Set<DateComponents> {
        let activities = try fetchCompletedActivities()
        let calendar = Calendar.current

        var components = activities.compactMap { activity -> DateComponents? in
            guard let date = activity.completedAt else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: date)
        }

        if let month = month {
            let targetMonth = calendar.component(.month, from: month)
            let targetYear = calendar.component(.year, from: month)
            components = components.filter {
                $0.month == targetMonth && $0.year == targetYear
            }
        }

        return Set(components)
    }

    // MARK: - Private Methods

    private func fetchCompletedLogs() throws -> [SessionLog] {
        let descriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchCompletedActivities() throws -> [ScheduledActivity] {
        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate { $0.isCompleted == true },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchAllRatings() throws -> [ExerciseRating] {
        let descriptor = FetchDescriptor<ExerciseRating>(
            sortBy: [SortDescriptor(\.ratedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func findFavoriteCategory() throws -> ExerciseCategory? {
        let ratings = try fetchAllRatings()
        let grouped = Dictionary(grouping: ratings, by: \.exerciseCategory)
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    private func calculateStreaks(from logs: [SessionLog]) -> (current: Int, longest: Int) {
        let calendar = Calendar.current
        let trainingDays = Set(logs.compactMap { log -> Date? in
            guard let date = log.completedAt else { return nil }
            return calendar.startOfDay(for: date)
        }).sorted(by: >)

        guard !trainingDays.isEmpty else { return (0, 0) }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let hasRecentTraining = trainingDays.contains(today) || trainingDays.contains(yesterday)

        var currentStreak = 0
        var longestStreak = 0
        var streakCount = 1
        var previousDay = trainingDays[0]

        for day in trainingDays.dropFirst() {
            let diff = calendar.dateComponents([.day], from: day, to: previousDay).day ?? 0

            if diff == 1 {
                streakCount += 1
            } else {
                longestStreak = max(longestStreak, streakCount)
                streakCount = 1
            }

            previousDay = day
        }

        longestStreak = max(longestStreak, streakCount)

        if hasRecentTraining {
            // Count current streak starting from most recent day
            currentStreak = 1
            var checkDate = trainingDays[0]

            for day in trainingDays.dropFirst() {
                let diff = calendar.dateComponents([.day], from: day, to: checkDate).day ?? 0
                if diff == 1 {
                    currentStreak += 1
                    checkDate = day
                } else {
                    break
                }
            }
        }

        return (currentStreak, longestStreak)
    }

    private func calculateTrend(for ratings: [ExerciseRating]) -> CategoryProgress.Trend {
        let sorted = ratings.sorted { $0.ratedAt < $1.ratedAt }
        guard sorted.count >= 4 else { return .stable }

        let midpoint = sorted.count / 2
        let firstHalf = sorted.prefix(midpoint)
        let secondHalf = sorted.suffix(midpoint)

        let firstAvg = Double(firstHalf.reduce(0) { $0 + $1.rating }) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0) { $0 + $1.rating }) / Double(secondHalf.count)

        let diff = secondAvg - firstAvg
        if diff > 0.3 { return .improving }
        if diff < -0.3 { return .declining }
        return .stable
    }
}
