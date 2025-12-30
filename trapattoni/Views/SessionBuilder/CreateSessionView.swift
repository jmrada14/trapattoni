import SwiftUI
import SwiftData

struct CreateSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let templateType: SessionTemplateType

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var defaultRestSeconds: Int = 30
    @State private var exercises: [SessionExerciseInput] = []
    @State private var showingExercisePicker = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    private var totalDuration: Int {
        exercises.reduce(0) { $0 + $1.durationSeconds + $1.restSeconds }
    }

    private var totalDurationFormatted: String {
        let minutes = totalDuration / 60
        return "\(minutes) min"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info
                Section("createSession.details".localized) {
                    TextField("createSession.name".localized, text: $name)

                    TextField("createSession.descriptionOptional".localized, text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Stepper("createSession.restBetween".localized(with: defaultRestSeconds), value: $defaultRestSeconds, in: 0...120, step: 15)
                }

                // Exercises
                Section {
                    if exercises.isEmpty {
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("createSession.addExercises".localized, systemImage: "plus.circle")
                        }
                    } else {
                        ForEach($exercises) { $exercise in
                            ExerciseInputRow(
                                exercise: $exercise,
                                defaultRest: defaultRestSeconds
                            )
                        }
                        .onDelete(perform: deleteExercises)
                        .onMove(perform: moveExercises)

                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("createSession.addMore".localized, systemImage: "plus.circle")
                        }
                    }
                } header: {
                    HStack {
                        Text("training.exercises".localized)
                        Spacer()
                        if !exercises.isEmpty {
                            Text("\(exercises.count) \("sessions.exercises".localized) • \(totalDurationFormatted)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("createSession.new".localized(with: templateType.localizedName))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) { saveSession() }
                        .disabled(!isValid)
                }

                #if os(iOS)
                if !exercises.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $exercises, defaultRestSeconds: defaultRestSeconds)
            }
            .observeLanguageChanges()
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        exercises.remove(atOffsets: offsets)
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        exercises.move(fromOffsets: source, toOffset: destination)
    }

    private func saveSession() {
        let session = TrainingSession(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            templateType: templateType,
            defaultRestSeconds: defaultRestSeconds,
            isTemplate: true
        )

        modelContext.insert(session)

        for (index, exerciseInput) in exercises.enumerated() {
            let sessionExercise = SessionExercise(
                exercise: exerciseInput.exercise,
                orderIndex: index,
                durationSeconds: exerciseInput.durationSeconds,
                restAfterSeconds: exerciseInput.restSeconds
            )
            sessionExercise.session = session
            modelContext.insert(sessionExercise)
        }

        dismiss()
    }
}

// MARK: - Exercise Input Model

struct SessionExerciseInput: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var durationSeconds: Int
    var restSeconds: Int
}

// MARK: - Exercise Input Row

struct ExerciseInputRow: View {
    @Binding var exercise: SessionExerciseInput
    let defaultRest: Int

    @State private var showingDurationPicker = false

    private var durationMinutes: Int {
        exercise.durationSeconds / 60
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CategoryIconView(category: ExerciseCategory(rawValue: exercise.exercise.categoryRaw) ?? .dribbling, size: .small)

                Text(exercise.exercise.localizedName)
                    .font(.headline)

                Spacer()
            }

            HStack(spacing: 16) {
                // Duration picker
                Menu {
                    ForEach([1, 2, 3, 5, 10, 15, 20], id: \.self) { minutes in
                        Button("exerciseInput.minutes".localized(with: minutes)) {
                            exercise.durationSeconds = minutes * 60
                        }
                    }
                } label: {
                    Label("exerciseInput.minutes".localized(with: durationMinutes), systemImage: "clock")
                        .font(.caption)
                }

                // Rest picker
                Menu {
                    Button("exerciseInput.noRest".localized) { exercise.restSeconds = 0 }
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { seconds in
                        Button("exerciseInput.restSeconds".localized(with: seconds)) {
                            exercise.restSeconds = seconds
                        }
                    }
                } label: {
                    Label(exercise.restSeconds == 0 ? "exerciseInput.noRest".localized : "exerciseInput.restSeconds".localized(with: exercise.restSeconds), systemImage: "pause.circle")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CreateSessionView(templateType: .quickSession)
        .modelContainer(for: [TrainingSession.self, Exercise.self], inMemory: true)
}
