import Foundation
import SwiftData

enum ExerciseDataSeeder {
    /// Seeds exercise data if no prebuilt exercises exist.
    /// Uses content-based detection instead of UserDefaults to work properly with CloudKit sync.
    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) async throws {
        // Check if we have any non-user-created exercises (from seed or sync)
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { !$0.isUserCreated }
        )
        let existingCount = try modelContext.fetchCount(descriptor)

        // Skip seeding if prebuilt exercises already exist (from local seed or CloudKit sync)
        guard existingCount == 0 else {
            return
        }

        // Load and parse JSON
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            throw SeedError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let exerciseData = try decoder.decode([ExerciseJSON].self, from: data)

        // Insert exercises
        for item in exerciseData {
            let exercise = item.toExercise()
            modelContext.insert(exercise)
        }

        try modelContext.save()
    }

    enum SeedError: Error, LocalizedError {
        case fileNotFound
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "exercises.json file not found in bundle"
            case .decodingFailed:
                return "Failed to decode exercises.json"
            }
        }
    }
}

// MARK: - JSON Decoding Structure

struct ExerciseJSON: Codable {
    let name: String
    let description: String
    let category: String
    let trainingType: String
    let skillLevel: String
    let duration: String
    let spaceRequired: String
    let equipment: [String]
    let videoURL: String?
    let coachingPoints: [String]
    let commonMistakes: [String]
    let variations: [String]
    let tags: [String]

    func toExercise() -> Exercise {
        Exercise(
            name: name,
            description: description,
            category: ExerciseCategory(rawValue: category) ?? .dribbling,
            trainingType: TrainingType(rawValue: trainingType) ?? .solo,
            skillLevel: SkillLevel(rawValue: skillLevel) ?? .beginner,
            duration: Duration(rawValue: duration) ?? .short,
            spaceRequired: SpaceRequired(rawValue: spaceRequired) ?? .small,
            equipment: equipment.compactMap { Equipment(rawValue: $0) },
            videoURL: videoURL,
            coachingPoints: coachingPoints,
            commonMistakes: commonMistakes,
            variations: variations,
            tags: tags,
            isUserCreated: false
        )
    }
}
