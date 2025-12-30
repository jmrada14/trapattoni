import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Basic info
    @State private var name = ""
    @State private var description = ""

    // Classification
    @State private var category: ExerciseCategory = .dribbling
    @State private var trainingType: TrainingType = .solo
    @State private var skillLevel: SkillLevel = .beginner
    @State private var duration: Duration = .short
    @State private var spaceRequired: SpaceRequired = .small

    // Equipment
    @State private var selectedEquipment: Set<Equipment> = []

    // Content
    @State private var videoURL = ""
    @State private var coachingPoints: [String] = [""]
    @State private var commonMistakes: [String] = [""]
    @State private var variations: [String] = [""]

    // Tags
    @State private var tagInput = ""
    @State private var tags: [String] = []

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Information
                Section("createExercise.basicInfo".localized) {
                    TextField("createExercise.name".localized, text: $name)

                    TextField("createExercise.description".localized, text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Classification
                Section("createExercise.classification".localized) {
                    Picker("exercise.category".localized, selection: $category) {
                        ForEach(ExerciseCategory.allCases) { cat in
                            Label(cat.localizedName, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    Picker("exercise.trainingType".localized, selection: $trainingType) {
                        ForEach(TrainingType.allCases) { type in
                            Label(type.localizedName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Picker("exercise.skillLevel".localized, selection: $skillLevel) {
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.localizedName).tag(level)
                        }
                    }

                    Picker("exercise.duration".localized, selection: $duration) {
                        ForEach(Duration.allCases) { dur in
                            Text(dur.localizedName).tag(dur)
                        }
                    }

                    Picker("exercise.space".localized, selection: $spaceRequired) {
                        ForEach(SpaceRequired.allCases) { space in
                            Text(space.localizedName).tag(space)
                        }
                    }
                }

                // Equipment
                Section("createExercise.equipmentNeeded".localized) {
                    ForEach(Equipment.allCases) { item in
                        Toggle(isOn: Binding(
                            get: { selectedEquipment.contains(item) },
                            set: { isSelected in
                                if isSelected {
                                    selectedEquipment.insert(item)
                                } else {
                                    selectedEquipment.remove(item)
                                }
                            }
                        )) {
                            Label(item.localizedName, systemImage: item.iconName)
                        }
                    }
                }

                // Video URL
                Section {
                    TextField("createExercise.youtubeURL".localized, text: $videoURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                } header: {
                    Text("createExercise.videoOptional".localized)
                } footer: {
                    Text("createExercise.videoFooter".localized)
                }

                // Coaching Points
                Section {
                    EditableListSection(
                        items: $coachingPoints,
                        placeholder: "createExercise.addCoachingPoint".localized
                    )
                } header: {
                    Text("createExercise.coachingPoints".localized)
                } footer: {
                    Text("createExercise.coachingPointsFooter".localized)
                }

                // Common Mistakes
                Section {
                    EditableListSection(
                        items: $commonMistakes,
                        placeholder: "createExercise.addMistake".localized
                    )
                } header: {
                    Text("createExercise.commonMistakes".localized)
                } footer: {
                    Text("createExercise.commonMistakesFooter".localized)
                }

                // Variations
                Section {
                    EditableListSection(
                        items: $variations,
                        placeholder: "createExercise.addVariation".localized
                    )
                } header: {
                    Text("createExercise.variations".localized)
                } footer: {
                    Text("createExercise.variationsFooter".localized)
                }

                // Tags
                Section {
                    TagInputView(tagInput: $tagInput, tags: $tags)
                } header: {
                    Text("createExercise.tags".localized)
                } footer: {
                    Text("createExercise.tagsFooter".localized)
                }
            }
            .navigationTitle("createExercise.title".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
            .observeLanguageChanges()
        }
    }

    private func saveExercise() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            category: category,
            trainingType: trainingType,
            skillLevel: skillLevel,
            duration: duration,
            spaceRequired: spaceRequired,
            equipment: Array(selectedEquipment),
            videoURL: videoURL.isEmpty ? nil : videoURL,
            coachingPoints: coachingPoints.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            commonMistakes: commonMistakes.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            variations: variations.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            tags: tags,
            isUserCreated: true
        )

        modelContext.insert(exercise)
        dismiss()
    }
}

// MARK: - Editable List Section

struct EditableListSection: View {
    @Binding var items: [String]
    let placeholder: String

    var body: some View {
        ForEach(items.indices, id: \.self) { index in
            HStack {
                TextField(placeholder, text: $items[index])

                if items.count > 1 {
                    Button {
                        items.remove(at: index)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }

        Button {
            items.append("")
        } label: {
            Label("Add", systemImage: "plus.circle.fill")
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Tag Input View

struct TagInputView: View {
    @Binding var tagInput: String
    @Binding var tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("createExercise.enterTag".localized, text: $tagInput)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        addTag()
                    }

                Button("common.add".localized) {
                    addTag()
                }
                .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.caption)

                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !tag.isEmpty, !tags.contains(tag) else { return }
        tags.append(tag)
        tagInput = ""
    }
}

#Preview {
    CreateExerciseView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
