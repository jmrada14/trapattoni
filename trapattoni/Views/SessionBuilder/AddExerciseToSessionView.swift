import SwiftUI
import SwiftData

/// View for adding exercises directly to an existing TrainingSession
struct AddExerciseToSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @Bindable var session: TrainingSession

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var selectedExercises: Set<UUID> = []

    private var filteredExercises: [Exercise] {
        allExercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.exerciseDescription.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == nil ||
                exercise.category == selectedCategory

            return matchesSearch && matchesCategory
        }
    }

    private var groupedExercises: [(ExerciseCategory, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises, by: \.category)
        return ExerciseCategory.allCases.compactMap { category in
            guard let exercises = grouped[category], !exercises.isEmpty else { return nil }
            return (category, exercises)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(ExerciseCategory.allCases) { category in
                            CategoryFilterChip(
                                title: category.rawValue,
                                icon: category.iconName,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(.bar)

                // Exercise list
                List {
                    ForEach(groupedExercises, id: \.0) { category, exercises in
                        Section(category.rawValue) {
                            ForEach(exercises) { exercise in
                                ExercisePickerRow(
                                    exercise: exercise,
                                    isSelected: selectedExercises.contains(exercise.id)
                                ) {
                                    toggleSelection(exercise)
                                }
                            }
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.inset)
                #endif
                .searchable(text: $searchText, prompt: "Search exercises...")

                // Selection summary bar
                if !selectedExercises.isEmpty {
                    HStack {
                        Text("\(selectedExercises.count) exercise\(selectedExercises.count == 1 ? "" : "s") selected")
                            .font(.headline)

                        Spacer()

                        Button("Add to Session") {
                            addSelectedExercises()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .background(.bar)
                }
            }
            .navigationTitle("Add Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func toggleSelection(_ exercise: Exercise) {
        if selectedExercises.contains(exercise.id) {
            selectedExercises.remove(exercise.id)
        } else {
            selectedExercises.insert(exercise.id)
        }
    }

    private func addSelectedExercises() {
        let currentMaxOrder = session.exercises.map { $0.orderIndex }.max() ?? -1

        for (index, exerciseId) in selectedExercises.enumerated() {
            guard let exercise = allExercises.first(where: { $0.id == exerciseId }) else { continue }

            let sessionExercise = SessionExercise(
                exercise: exercise,
                orderIndex: currentMaxOrder + 1 + index,
                durationSeconds: 300, // 5 minutes default
                restAfterSeconds: session.defaultRestSeconds
            )
            session.exercises.append(sessionExercise)
        }

        session.updatedAt = Date()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TrainingSession.self, Exercise.self, configurations: config)

    let session = TrainingSession(name: "Test Session", description: "", templateType: .custom)
    container.mainContext.insert(session)

    return AddExerciseToSessionView(session: session)
        .modelContainer(container)
}
