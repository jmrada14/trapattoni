import Foundation
import SwiftData

@Model
final class ExerciseRating {
    var id: UUID = UUID()
    var exerciseId: UUID = UUID()
    var exerciseName: String = ""
    var exerciseCategoryRaw: String = "Dribbling"
    var rating: Int = 3
    var ratedAt: Date = Date()
    var notes: String = ""

    var sessionLog: SessionLog? = nil

    // MARK: - Computed Properties

    var exerciseCategory: ExerciseCategory {
        ExerciseCategory(rawValue: exerciseCategoryRaw) ?? .dribbling
    }

    var ratingStars: String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: 5 - rating)
    }

    // MARK: - Initializers

    init(exercise: Exercise, rating: Int) {
        self.id = UUID()
        self.exerciseId = exercise.id
        self.exerciseName = exercise.name
        self.exerciseCategoryRaw = exercise.categoryRaw
        self.rating = min(5, max(1, rating))
        self.ratedAt = Date()
        self.notes = ""
    }

    init(
        exerciseId: UUID,
        exerciseName: String,
        exerciseCategory: ExerciseCategory,
        rating: Int
    ) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.exerciseCategoryRaw = exerciseCategory.rawValue
        self.rating = min(5, max(1, rating))
        self.ratedAt = Date()
        self.notes = ""
    }
}
