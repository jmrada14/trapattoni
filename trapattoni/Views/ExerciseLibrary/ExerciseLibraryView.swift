import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var filter = ExerciseFilter()
    @State private var showingFilters = false
    @State private var showingCreateExercise = false
    @State private var selectedExercise: Exercise?

    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            // Search text filter
            let matchesSearch = filter.searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(filter.searchText) ||
                exercise.exerciseDescription.localizedCaseInsensitiveContains(filter.searchText) ||
                exercise.tags.contains { $0.localizedCaseInsensitiveContains(filter.searchText) }

            // Category filter
            let matchesCategory = filter.selectedCategories.isEmpty ||
                filter.selectedCategories.contains(exercise.category)

            // Training type filter
            let matchesTrainingType = filter.selectedTrainingTypes.isEmpty ||
                filter.selectedTrainingTypes.contains(exercise.trainingType)

            // Skill level filter
            let matchesSkillLevel = filter.selectedSkillLevels.isEmpty ||
                filter.selectedSkillLevels.contains(exercise.skillLevel)

            // Duration filter
            let matchesDuration = filter.selectedDurations.isEmpty ||
                filter.selectedDurations.contains(exercise.duration)

            // Space filter
            let matchesSpace = filter.selectedSpaces.isEmpty ||
                filter.selectedSpaces.contains(exercise.spaceRequired)

            // Equipment filter - exercise must have at least one of the selected equipment
            let matchesEquipment = filter.selectedEquipment.isEmpty ||
                !filter.selectedEquipment.isDisjoint(with: Set(exercise.equipment))

            // Favorites filter
            let matchesFavorites = !filter.showFavoritesOnly || exercise.isFavorite

            // User created filter
            let matchesUserCreated = !filter.showUserCreatedOnly || exercise.isUserCreated

            return matchesSearch && matchesCategory && matchesTrainingType &&
                   matchesSkillLevel && matchesDuration && matchesSpace &&
                   matchesEquipment && matchesFavorites && matchesUserCreated
        }
    }

    var body: some View {
        NavigationStack {
            ExerciseListView(
                exercises: filteredExercises,
                selectedExercise: $selectedExercise
            )
            .searchable(text: $filter.searchText, prompt: "Search exercises...")
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }

                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    filterButton
                }
                #else
                ToolbarItem(placement: .secondaryAction) {
                    filterButton
                }
                #endif
            }
            .sheet(isPresented: $showingFilters) {
                ExerciseFilterView(filter: filter)
                    #if os(macOS)
                    .frame(minWidth: 400, minHeight: 500)
                    #endif
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseView()
                    #if os(macOS)
                    .frame(minWidth: 500, minHeight: 600)
                    #endif
            }
            .navigationDestination(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    private var filterButton: some View {
        Button {
            showingFilters = true
        } label: {
            if filter.hasActiveFilters {
                Label("Filter (\(filter.activeFilterCount))", systemImage: "line.3.horizontal.decrease.circle.fill")
            } else {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }
}

#Preview {
    ExerciseLibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
