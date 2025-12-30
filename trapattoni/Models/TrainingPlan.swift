import Foundation
import SwiftData

@Model
final class TrainingPlan {
    var id: UUID = UUID()
    var name: String = ""
    var planDescription: String = ""
    var durationWeeks: Int = 4
    var targetSessionsPerWeek: Int = 3
    var isPrebuilt: Bool = false

    var startedAt: Date? = nil
    var completedAt: Date? = nil
    var pausedAt: Date? = nil

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \PlanSession.plan)
    var sessions: [PlanSession] = []

    // MARK: - Computed Properties

    var isActive: Bool {
        startedAt != nil && completedAt == nil && pausedAt == nil
    }

    var isPaused: Bool {
        startedAt != nil && pausedAt != nil && completedAt == nil
    }

    var isNotStarted: Bool {
        startedAt == nil
    }

    var isFinished: Bool {
        completedAt != nil
    }

    var totalSessions: Int {
        sessions.count
    }

    var completedSessions: Int {
        sessions.filter { $0.isCompleted }.count
    }

    var progressPercentage: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(completedSessions) / Double(totalSessions)
    }

    var progressFormatted: String {
        "\(completedSessions)/\(totalSessions) sessions"
    }

    var currentWeek: Int {
        guard let startedAt else { return 0 }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        return min((daysSinceStart / 7) + 1, durationWeeks)
    }

    var sortedSessions: [PlanSession] {
        sessions.sorted { session1, session2 in
            if session1.weekNumber != session2.weekNumber {
                return session1.weekNumber < session2.weekNumber
            }
            return session1.orderInWeek < session2.orderInWeek
        }
    }

    var sessionsByWeek: [(week: Int, sessions: [PlanSession])] {
        let grouped = Dictionary(grouping: sessions, by: \.weekNumber)
        return (1...durationWeeks).compactMap { week in
            guard let weekSessions = grouped[week] else { return nil }
            return (week, weekSessions.sorted { $0.orderInWeek < $1.orderInWeek })
        }
    }

    /// Returns localized name if stored value is a translation key, otherwise returns raw name
    var localizedName: String {
        let translated = name.localized
        // If translation exists (different from key), use it; otherwise use raw name
        return translated != name ? translated : name
    }

    /// Returns localized description if stored value is a translation key, otherwise returns raw description
    var localizedDescription: String {
        let translated = planDescription.localized
        return translated != planDescription ? translated : planDescription
    }

    // MARK: - Initializer

    init(
        name: String,
        description: String = "",
        durationWeeks: Int = 4,
        targetSessionsPerWeek: Int = 3,
        isPrebuilt: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.planDescription = description
        self.durationWeeks = durationWeeks
        self.targetSessionsPerWeek = targetSessionsPerWeek
        self.isPrebuilt = isPrebuilt
        self.startedAt = nil
        self.completedAt = nil
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sessions = []
    }

    // MARK: - Methods

    func start() {
        startedAt = Date()
        updatedAt = Date()
    }

    func checkCompletion() {
        if sessions.allSatisfy({ $0.isCompleted }) && !sessions.isEmpty {
            completedAt = Date()
            updatedAt = Date()
        }
    }

    func addSession(_ trainingSession: TrainingSession, weekNumber: Int, orderInWeek: Int) {
        let planSession = PlanSession(
            session: trainingSession,
            weekNumber: weekNumber,
            orderInWeek: orderInWeek
        )
        planSession.plan = self
        sessions.append(planSession)
        updatedAt = Date()
    }

    /// Restart the plan, resetting all progress
    func restart() {
        startedAt = nil
        completedAt = nil

        // Reset all session completions
        for session in sessions {
            session.resetCompletion()
        }

        updatedAt = Date()
    }

    /// Pause the active plan
    func pause() {
        pausedAt = Date()
        updatedAt = Date()
    }

    /// Resume a paused plan
    func resume() {
        pausedAt = nil
        updatedAt = Date()
    }
}
