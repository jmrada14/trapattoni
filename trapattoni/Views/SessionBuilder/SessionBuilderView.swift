import SwiftUI
import SwiftData

struct SessionBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingSession.updatedAt, order: .reverse)
    private var sessions: [TrainingSession]

    @State private var showingCreateSession = false
    @State private var selectedTemplateType: SessionTemplateType = .custom
    @State private var selectedSession: TrainingSession?
    @State private var sessionToDelete: TrainingSession?
    @State private var showingDeleteAlert = false

    private var templateSessions: [TrainingSession] {
        sessions.filter { $0.isTemplate }
    }

    var body: some View {
        NavigationStack {
            List {
                // Quick Start Section
                Section {
                    ForEach(SessionTemplateType.allCases) { type in
                        Button {
                            selectedTemplateType = type
                            showingCreateSession = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.iconName)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.localizedName)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(type.localizedDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("~\(type.suggestedDurationMinutes) \("time.min".localized)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("sessions.quickStart".localized)
                }

                // Saved Sessions Section
                Section {
                    if templateSessions.isEmpty {
                        ContentUnavailableView(
                            "sessions.noSessions".localized,
                            systemImage: "figure.run",
                            description: Text("sessions.createFirst".localized)
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(templateSessions) { session in
                            SessionRowView(session: session)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSession = session
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("common.delete".localized, systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        duplicateSession(session)
                                    } label: {
                                        Label("sessions.duplicate".localized, systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                } header: {
                    Text("sessions.mySessions".localized)
                } footer: {
                    if !templateSessions.isEmpty {
                        Text("sessions.swipeHint".localized)
                    }
                }
            }
            .navigationTitle("sessions.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedTemplateType = .custom
                        showingCreateSession = true
                    } label: {
                        Label("sessions.new".localized, systemImage: "plus")
                    }
                }
            }
            .observeLanguageChanges()
            .sheet(isPresented: $showingCreateSession) {
                CreateSessionView(templateType: selectedTemplateType)
            }
            .navigationDestination(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .alert("sessions.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) {
                    sessionToDelete = nil
                }
                Button("common.delete".localized, role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                }
            } message: {
                Text("sessions.deleteConfirm".localized)
            }
        }
    }

    private func duplicateSession(_ session: TrainingSession) {
        let duplicate = TrainingSession(
            name: "\(session.localizedName) (Copy)",
            description: session.sessionDescription,
            templateType: session.templateType
        )
        duplicate.defaultRestSeconds = session.defaultRestSeconds
        duplicate.isTemplate = true

        // Duplicate exercises
        for exercise in session.sortedExercises {
            let duplicateExercise = SessionExercise(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                exerciseCategory: exercise.exerciseCategory,
                durationSeconds: exercise.durationSeconds,
                restAfterSeconds: exercise.restAfterSeconds,
                orderIndex: exercise.orderIndex,
                notes: exercise.notes
            )
            duplicate.exercises.append(duplicateExercise)
        }

        modelContext.insert(duplicate)
    }

    private func deleteSession(_ session: TrainingSession) {
        modelContext.delete(session)
        sessionToDelete = nil
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: TrainingSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.templateType.iconName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(session.localizedName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(session.exerciseCount) \("sessions.exercises".localized)", systemImage: "list.bullet")
                    Label(session.totalDurationFormatted, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SessionBuilderView()
        .modelContainer(for: [TrainingSession.self, Exercise.self], inMemory: true)
}
