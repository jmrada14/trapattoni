import Foundation
import SwiftData

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var orderIndex: Int = 0
    var durationSeconds: Int = 300
    var restAfterSeconds: Int = 30
    var notes: String = ""

    // Relationship
    var session: TrainingSession? = nil

    // Denormalized exercise data (in case original exercise is deleted)
    var exerciseId: UUID = UUID()
    var exerciseName: String = ""
    var exerciseCategoryRaw: String = "Dribbling"

    // MARK: - Computed Properties

    var exerciseCategory: ExerciseCategory {
        ExerciseCategory(rawValue: exerciseCategoryRaw) ?? .dribbling
    }

    /// Returns localized exercise name if stored value is a translation key, otherwise returns raw name
    var localizedExerciseName: String {
        let translated = exerciseName.localized
        // If translation exists (different from key), use it; otherwise use raw name
        return translated != exerciseName ? translated : exerciseName
    }

    var durationFormatted: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    var restFormatted: String {
        if restAfterSeconds == 0 {
            return "No rest"
        }
        if restAfterSeconds < 60 {
            return "\(restAfterSeconds)s rest"
        }
        let minutes = restAfterSeconds / 60
        return "\(minutes) min rest"
    }

    // MARK: - Initializers

    init(
        exercise: Exercise,
        orderIndex: Int,
        durationSeconds: Int = 300,
        restAfterSeconds: Int = 30
    ) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.durationSeconds = durationSeconds
        self.restAfterSeconds = restAfterSeconds
        self.notes = ""
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.exerciseCategoryRaw = exercise.categoryRaw
    }

    /// Initialize from denormalized data (for duplication)
    init(
        exerciseId: UUID,
        exerciseName: String,
        exerciseCategory: ExerciseCategory,
        durationSeconds: Int,
        restAfterSeconds: Int,
        orderIndex: Int,
        notes: String = ""
    ) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.durationSeconds = durationSeconds
        self.restAfterSeconds = restAfterSeconds
        self.notes = notes
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.exerciseCategoryRaw = exerciseCategory.rawValue
    }
}
