import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    let exercises: [Exercise]
    @Binding var selectedExercise: Exercise?

    @State private var exerciseToEdit: Exercise?
    @State private var exerciseToDelete: Exercise?
    @State private var showingDeleteAlert = false

    // Group exercises by category for section headers
    private var groupedExercises: [(ExerciseCategory, [Exercise])] {
        let grouped = Dictionary(grouping: exercises, by: \.category)
        return ExerciseCategory.allCases.compactMap { category in
            guard let exercises = grouped[category], !exercises.isEmpty else { return nil }
            return (category, exercises.sorted { $0.name < $1.name })
        }
    }

    var body: some View {
        List {
            ForEach(groupedExercises, id: \.0) { category, categoryExercises in
                Section {
                    ForEach(categoryExercises) { exercise in
                        ExerciseCardView(exercise: exercise)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExercise = exercise
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Delete - only for user created exercises
                                if exercise.isUserCreated {
                                    Button(role: .destructive) {
                                        exerciseToDelete = exercise
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // Edit
                                Button {
                                    exerciseToEdit = exercise
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                // Favorite
                                Button {
                                    exercise.isFavorite.toggle()
                                } label: {
                                    Label(
                                        exercise.isFavorite ? "Unfavorite" : "Favorite",
                                        systemImage: exercise.isFavorite ? "heart.slash" : "heart"
                                    )
                                }
                                .tint(exercise.isFavorite ? .gray : .red)

                                // Duplicate
                                Button {
                                    duplicateExercise(exercise)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(.orange)
                            }
                    }
                } header: {
                    Label(category.rawValue, systemImage: category.iconName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
        .overlay {
            if exercises.isEmpty {
                ContentUnavailableView(
                    "No Exercises Found",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your filters or search terms.")
                )
            }
        }
        .sheet(item: $exerciseToEdit) { exercise in
            EditExerciseView(exercise: exercise)
        }
        .alert("Delete Exercise?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                exerciseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let exercise = exerciseToDelete {
                    deleteExercise(exercise)
                }
            }
        } message: {
            Text("This will permanently delete \"\(exerciseToDelete?.name ?? "this exercise")\". This cannot be undone.")
        }
    }

    private func duplicateExercise(_ exercise: Exercise) {
        let duplicate = Exercise(
            name: "\(exercise.name) (Copy)",
            description: exercise.exerciseDescription,
            category: exercise.category,
            trainingType: exercise.trainingType,
            skillLevel: exercise.skillLevel,
            duration: exercise.duration,
            spaceRequired: exercise.spaceRequired,
            equipment: exercise.equipment,
            videoURL: exercise.videoURL,
            coachingPoints: exercise.coachingPoints,
            commonMistakes: exercise.commonMistakes,
            variations: exercise.variations,
            tags: exercise.tags
        )
        duplicate.isUserCreated = true
        modelContext.insert(duplicate)
    }

    private func deleteExercise(_ exercise: Exercise) {
        modelContext.delete(exercise)
        exerciseToDelete = nil
    }
}

// MARK: - Edit Exercise View

struct EditExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var exercise: Exercise

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var category: ExerciseCategory = .dribbling
    @State private var trainingType: TrainingType = .solo
    @State private var skillLevel: SkillLevel = .beginner
    @State private var duration: Duration = .medium
    @State private var spaceRequired: SpaceRequired = .medium
    @State private var selectedEquipment: Set<Equipment> = []
    @State private var videoURL: String = ""
    @State private var coachingPointsText: String = ""
    @State private var commonMistakesText: String = ""
    @State private var variationsText: String = ""
    @State private var tagsText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Exercise Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }

                    Picker("Training Type", selection: $trainingType) {
                        ForEach(TrainingType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }

                Section("Requirements") {
                    Picker("Duration", selection: $duration) {
                        ForEach(Duration.allCases, id: \.self) { dur in
                            Text(dur.rawValue).tag(dur)
                        }
                    }

                    Picker("Space Required", selection: $spaceRequired) {
                        ForEach(SpaceRequired.allCases, id: \.self) { space in
                            Text(space.rawValue).tag(space)
                        }
                    }
                }

                Section("Equipment") {
                    ForEach(Equipment.allCases, id: \.self) { equip in
                        Toggle(equip.rawValue, isOn: Binding(
                            get: { selectedEquipment.contains(equip) },
                            set: { isSelected in
                                if isSelected {
                                    selectedEquipment.insert(equip)
                                } else {
                                    selectedEquipment.remove(equip)
                                }
                            }
                        ))
                    }
                }

                Section("Video URL (Optional)") {
                    TextField("YouTube or video URL", text: $videoURL)
                        .textContentType(.URL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        #endif
                }

                Section("Coaching Points") {
                    TextField("One per line", text: $coachingPointsText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Common Mistakes") {
                    TextField("One per line", text: $commonMistakesText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Variations") {
                    TextField("One per line", text: $variationsText, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Tags") {
                    TextField("Comma separated", text: $tagsText)
                }
            }
            .navigationTitle("Edit Exercise")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadExerciseData()
            }
        }
    }

    private func loadExerciseData() {
        name = exercise.name
        description = exercise.exerciseDescription
        category = exercise.category
        trainingType = exercise.trainingType
        skillLevel = exercise.skillLevel
        duration = exercise.duration
        spaceRequired = exercise.spaceRequired
        selectedEquipment = Set(exercise.equipment)
        videoURL = exercise.videoURL ?? ""
        coachingPointsText = exercise.coachingPoints.joined(separator: "\n")
        commonMistakesText = exercise.commonMistakes.joined(separator: "\n")
        variationsText = exercise.variations.joined(separator: "\n")
        tagsText = exercise.tags.joined(separator: ", ")
    }

    private func saveExercise() {
        exercise.name = name
        exercise.exerciseDescription = description
        exercise.category = category
        exercise.trainingType = trainingType
        exercise.skillLevel = skillLevel
        exercise.duration = duration
        exercise.spaceRequired = spaceRequired
        exercise.equipment = Array(selectedEquipment)
        exercise.videoURL = videoURL.isEmpty ? nil : videoURL
        exercise.coachingPoints = coachingPointsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        exercise.commonMistakes = commonMistakesText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        exercise.variations = variationsText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        exercise.tags = tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    @Previewable @State var selected: Exercise?

    ExerciseListView(
        exercises: [
            Exercise(
                name: "Cone Weave",
                description: "Basic dribbling through cones",
                category: .dribbling,
                trainingType: .solo,
                skillLevel: .beginner,
                duration: .short,
                spaceRequired: .small,
                equipment: [.ball, .cones]
            ),
            Exercise(
                name: "Wall Passing",
                description: "Passing practice against a wall",
                category: .passing,
                trainingType: .solo,
                skillLevel: .beginner,
                duration: .medium,
                spaceRequired: .small,
                equipment: [.ball, .wall]
            )
        ],
        selectedExercise: $selected
    )
}
