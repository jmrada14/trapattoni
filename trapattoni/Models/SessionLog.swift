import Foundation
import SwiftData

@Model
final class SessionLog {
    var id: UUID = UUID()
    var sessionName: String = ""
    var sessionId: UUID? = nil
    var planId: UUID? = nil

    var startedAt: Date = Date()
    var completedAt: Date? = nil
    var actualDurationSeconds: Int = 0

    var exercisesCompleted: Int = 0
    var exercisesTotal: Int = 0

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ExerciseRating.sessionLog)
    var ratings: [ExerciseRating] = []

    // MARK: - Computed Properties

    var isCompleted: Bool {
        completedAt != nil
    }

    var completionPercentage: Double {
        guard exercisesTotal > 0 else { return 0 }
        return Double(exercisesCompleted) / Double(exercisesTotal)
    }

    var actualDurationFormatted: String {
        let minutes = actualDurationSeconds / 60
        let seconds = actualDurationSeconds % 60
        if minutes < 60 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return String(format: "%d:%02d:%02d", hours, remainingMinutes, seconds)
    }

    var averageRating: Double? {
        guard !ratings.isEmpty else { return nil }
        let total = ratings.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(ratings.count)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startedAt)
    }

    // MARK: - Initializer

    init(session: TrainingSession, planId: UUID? = nil) {
        self.id = UUID()
        self.sessionName = session.name
        self.sessionId = session.id
        self.planId = planId
        self.startedAt = Date()
        self.completedAt = nil
        self.actualDurationSeconds = 0
        self.exercisesCompleted = 0
        self.exercisesTotal = session.exercises.count
        self.ratings = []
    }

    // MARK: - Methods

    func complete(exercisesCompleted: Int, actualDuration: Int) {
        self.completedAt = Date()
        self.exercisesCompleted = exercisesCompleted
        self.actualDurationSeconds = actualDuration
    }

    func addRating(_ rating: ExerciseRating) {
        rating.sessionLog = self
        ratings.append(rating)
    }
}
