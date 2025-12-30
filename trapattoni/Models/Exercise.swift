import Foundation
import SwiftData

@Model
final class Exercise {
    // MARK: - Identity
    var id: UUID = UUID()
    var name: String = ""
    var exerciseDescription: String = ""

    // MARK: - Classification (stored as raw strings for SwiftData)
    var categoryRaw: String = "Dribbling"
    var trainingTypeRaw: String = "Solo"
    var skillLevelRaw: String = "Beginner"
    var durationRaw: String = "Short (5-10 min)"
    var spaceRequiredRaw: String = "Small"

    // MARK: - Equipment (stored as comma-separated string)
    var equipmentRaw: String = ""

    // MARK: - Content
    var videoURL: String? = nil
    var coachingPoints: [String] = []
    var commonMistakes: [String] = []
    var variations: [String] = []
    var tags: [String] = []

    // MARK: - Metadata
    var isUserCreated: Bool = false
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Computed Properties
    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .dribbling }
        set { categoryRaw = newValue.rawValue }
    }

    var trainingType: TrainingType {
        get { TrainingType(rawValue: trainingTypeRaw) ?? .solo }
        set { trainingTypeRaw = newValue.rawValue }
    }

    var skillLevel: SkillLevel {
        get { SkillLevel(rawValue: skillLevelRaw) ?? .beginner }
        set { skillLevelRaw = newValue.rawValue }
    }

    var duration: Duration {
        get { Duration(rawValue: durationRaw) ?? .short }
        set { durationRaw = newValue.rawValue }
    }

    var spaceRequired: SpaceRequired {
        get { SpaceRequired(rawValue: spaceRequiredRaw) ?? .small }
        set { spaceRequiredRaw = newValue.rawValue }
    }

    var equipment: [Equipment] {
        get {
            guard !equipmentRaw.isEmpty else { return [] }
            return equipmentRaw.split(separator: ",")
                .compactMap { Equipment(rawValue: String($0)) }
        }
        set {
            equipmentRaw = newValue.map(\.rawValue).joined(separator: ",")
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
        let translated = exerciseDescription.localized
        return translated != exerciseDescription ? translated : exerciseDescription
    }

    // MARK: - Initializer
    init(
        name: String,
        description: String,
        category: ExerciseCategory,
        trainingType: TrainingType,
        skillLevel: SkillLevel,
        duration: Duration,
        spaceRequired: SpaceRequired,
        equipment: [Equipment] = [],
        videoURL: String? = nil,
        coachingPoints: [String] = [],
        commonMistakes: [String] = [],
        variations: [String] = [],
        tags: [String] = [],
        isUserCreated: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.exerciseDescription = description
        self.categoryRaw = category.rawValue
        self.trainingTypeRaw = trainingType.rawValue
        self.skillLevelRaw = skillLevel.rawValue
        self.durationRaw = duration.rawValue
        self.spaceRequiredRaw = spaceRequired.rawValue
        self.equipmentRaw = equipment.map(\.rawValue).joined(separator: ",")
        self.videoURL = videoURL
        self.coachingPoints = coachingPoints
        self.commonMistakes = commonMistakes
        self.variations = variations
        self.tags = tags
        self.isUserCreated = isUserCreated
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
