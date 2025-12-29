import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @Binding var selectedExercises: [SessionExerciseInput]
    let defaultRestSeconds: Int

    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?
    @State private var tempSelection: Set<UUID> = []

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
                                    isSelected: tempSelection.contains(exercise.id)
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
                if !tempSelection.isEmpty {
                    SelectionSummaryBar(
                        count: tempSelection.count,
                        onAdd: addSelectedExercises
                    )
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
            .onAppear {
                // Pre-select already added exercises
                tempSelection = Set(selectedExercises.map { $0.exercise.id })
            }
        }
    }

    private func toggleSelection(_ exercise: Exercise) {
        if tempSelection.contains(exercise.id) {
            tempSelection.remove(exercise.id)
        } else {
            tempSelection.insert(exercise.id)
        }
    }

    private func addSelectedExercises() {
        // Find newly selected exercises (not already in the list)
        let existingIds = Set(selectedExercises.map { $0.exercise.id })
        let newExercises = allExercises.filter {
            tempSelection.contains($0.id) && !existingIds.contains($0.id)
        }

        // Add new exercises with default durations
        for exercise in newExercises {
            let input = SessionExerciseInput(
                exercise: exercise,
                durationSeconds: 300, // 5 minutes default
                restSeconds: defaultRestSeconds
            )
            selectedExercises.append(input)
        }

        // Remove deselected exercises
        selectedExercises.removeAll { !tempSelection.contains($0.exercise.id) }

        dismiss()
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.secondaryBackground)
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Picker Row

struct ExercisePickerRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(exercise.exerciseDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                SkillLevelBadge(level: exercise.skillLevel)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selection Summary Bar

struct SelectionSummaryBar: View {
    let count: Int
    let onAdd: () -> Void

    var body: some View {
        HStack {
            Text("\(count) exercise\(count == 1 ? "" : "s") selected")
                .font(.headline)

            Spacer()

            Button("Add to Session", action: onAdd)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.bar)
    }
}

#Preview {
    @Previewable @State var exercises: [SessionExerciseInput] = []

    ExercisePickerView(selectedExercises: $exercises, defaultRestSeconds: 30)
        .modelContainer(for: Exercise.self, inMemory: true)
}
