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
                Section("Basic Information") {
                    TextField("Exercise Name", text: $name)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Classification
                Section("Classification") {
                    Picker("Category", selection: $category) {
                        ForEach(ExerciseCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    Picker("Training Type", selection: $trainingType) {
                        ForEach(TrainingType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Picker("Skill Level", selection: $skillLevel) {
                        ForEach(SkillLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }

                    Picker("Duration", selection: $duration) {
                        ForEach(Duration.allCases) { dur in
                            Text(dur.rawValue).tag(dur)
                        }
                    }

                    Picker("Space Required", selection: $spaceRequired) {
                        ForEach(SpaceRequired.allCases) { space in
                            Text(space.rawValue).tag(space)
                        }
                    }
                }

                // Equipment
                Section("Equipment Needed") {
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
                            Label(item.rawValue, systemImage: item.iconName)
                        }
                    }
                }

                // Video URL
                Section {
                    TextField("YouTube URL", text: $videoURL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                        .autocorrectionDisabled()
                } header: {
                    Text("Video (Optional)")
                } footer: {
                    Text("Paste a YouTube video URL for demonstration")
                }

                // Coaching Points
                Section {
                    EditableListSection(
                        items: $coachingPoints,
                        placeholder: "Add coaching point..."
                    )
                } header: {
                    Text("Coaching Points")
                } footer: {
                    Text("Key things players should focus on")
                }

                // Common Mistakes
                Section {
                    EditableListSection(
                        items: $commonMistakes,
                        placeholder: "Add common mistake..."
                    )
                } header: {
                    Text("Common Mistakes")
                } footer: {
                    Text("Errors to watch out for and avoid")
                }

                // Variations
                Section {
                    EditableListSection(
                        items: $variations,
                        placeholder: "Add variation..."
                    )
                } header: {
                    Text("Variations & Progressions")
                } footer: {
                    Text("Ways to make the exercise easier or harder")
                }

                // Tags
                Section {
                    TagInputView(tagInput: $tagInput, tags: $tags)
                } header: {
                    Text("Tags")
                } footer: {
                    Text("Add tags to help with search and discovery")
                }
            }
            .navigationTitle("New Exercise")
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
                    }
                    .disabled(!isValid)
                }
            }
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
                TextField("Enter tag...", text: $tagInput)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit {
                        addTag()
                    }

                Button("Add") {
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
