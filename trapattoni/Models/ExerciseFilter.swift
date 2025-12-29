import Foundation

@Observable
class ExerciseFilter {
    var searchText: String = ""
    var selectedCategories: Set<ExerciseCategory> = []
    var selectedTrainingTypes: Set<TrainingType> = []
    var selectedSkillLevels: Set<SkillLevel> = []
    var selectedDurations: Set<Duration> = []
    var selectedSpaces: Set<SpaceRequired> = []
    var selectedEquipment: Set<Equipment> = []
    var showFavoritesOnly: Bool = false
    var showUserCreatedOnly: Bool = false

    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty ||
        !selectedTrainingTypes.isEmpty ||
        !selectedSkillLevels.isEmpty ||
        !selectedDurations.isEmpty ||
        !selectedSpaces.isEmpty ||
        !selectedEquipment.isEmpty ||
        showFavoritesOnly ||
        showUserCreatedOnly
    }

    var activeFilterCount: Int {
        var count = 0
        count += selectedCategories.count
        count += selectedTrainingTypes.count
        count += selectedSkillLevels.count
        count += selectedDurations.count
        count += selectedSpaces.count
        count += selectedEquipment.count
        if showFavoritesOnly { count += 1 }
        if showUserCreatedOnly { count += 1 }
        return count
    }

    func reset() {
        searchText = ""
        selectedCategories = []
        selectedTrainingTypes = []
        selectedSkillLevels = []
        selectedDurations = []
        selectedSpaces = []
        selectedEquipment = []
        showFavoritesOnly = false
        showUserCreatedOnly = false
    }
}
