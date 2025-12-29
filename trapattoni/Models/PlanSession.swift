import Foundation
import SwiftData

@Model
final class PlanSession {
    var id: UUID = UUID()
    var weekNumber: Int = 1
    var orderInWeek: Int = 0
    var sessionId: UUID = UUID()
    var sessionName: String = ""

    var completedAt: Date? = nil
    var sessionLogId: UUID? = nil

    var plan: TrainingPlan? = nil

    // MARK: - Computed Properties

    var isCompleted: Bool {
        completedAt != nil
    }

    var completedDateFormatted: String? {
        guard let completedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: completedAt)
    }

    // MARK: - Initializers

    init(
        session: TrainingSession,
        weekNumber: Int,
        orderInWeek: Int
    ) {
        self.id = UUID()
        self.weekNumber = weekNumber
        self.orderInWeek = orderInWeek
        self.sessionId = session.id
        self.sessionName = session.name
        self.completedAt = nil
        self.sessionLogId = nil
    }

    init(
        sessionId: UUID,
        sessionName: String,
        week: Int,
        dayOfWeek: Int,
        orderIndex: Int
    ) {
        self.id = UUID()
        self.weekNumber = week
        self.orderInWeek = orderIndex
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.completedAt = nil
        self.sessionLogId = nil
    }

    // MARK: - Methods

    func markCompleted(with log: SessionLog) {
        completedAt = Date()
        sessionLogId = log.id
        plan?.checkCompletion()
    }

    func resetCompletion() {
        completedAt = nil
        sessionLogId = nil
    }
}
