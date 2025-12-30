import Foundation
import SwiftData

@Model
final class TrainingSession {
    var id: UUID = UUID()
    var name: String = ""
    var sessionDescription: String = ""
    var templateTypeRaw: String = "Custom"

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    // Settings
    var defaultRestSeconds: Int = 30
    var isTemplate: Bool = true

    // Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Computed Properties

    var templateType: SessionTemplateType {
        get { SessionTemplateType(rawValue: templateTypeRaw) ?? .custom }
        set { templateTypeRaw = newValue.rawValue }
    }

    var sortedExercises: [SessionExercise] {
        exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var totalDurationSeconds: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.durationSeconds + exercise.restAfterSeconds
        }
    }

    var totalDurationFormatted: String {
        let totalMinutes = totalDurationSeconds / 60
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }

    var exerciseCount: Int {
        exercises.count
    }

    /// Returns localized name if stored value is a translation key, otherwise returns raw name
    var localizedName: String {
        let translated = name.localized
        // If translation exists (different from key), use it; otherwise use raw name
        return translated != name ? translated : name
    }

    /// Returns localized description if stored value is a translation key, otherwise returns raw description
    var localizedDescription: String {
        let translated = sessionDescription.localized
        return translated != sessionDescription ? translated : sessionDescription
    }

    // MARK: - Initializer

    init(
        name: String,
        description: String = "",
        templateType: SessionTemplateType = .custom,
        defaultRestSeconds: Int = 30,
        isTemplate: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.sessionDescription = description
        self.templateTypeRaw = templateType.rawValue
        self.exercises = []
        self.defaultRestSeconds = defaultRestSeconds
        self.isTemplate = isTemplate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    func addExercise(_ exercise: Exercise, durationSeconds: Int? = nil, restAfterSeconds: Int? = nil) {
        let sessionExercise = SessionExercise(
            exercise: exercise,
            orderIndex: exercises.count,
            durationSeconds: durationSeconds ?? 300,
            restAfterSeconds: restAfterSeconds ?? defaultRestSeconds
        )
        sessionExercise.session = self
        exercises.append(sessionExercise)
        updatedAt = Date()
    }

    func reorderExercises(_ exercises: [SessionExercise]) {
        for (index, exercise) in exercises.enumerated() {
            exercise.orderIndex = index
        }
        updatedAt = Date()
    }
}
