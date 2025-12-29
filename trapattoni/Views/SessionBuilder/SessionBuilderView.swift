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
                                    Text(type.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(type.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("~\(type.suggestedDurationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Quick Start")
                }

                // Saved Sessions Section
                Section {
                    if templateSessions.isEmpty {
                        ContentUnavailableView(
                            "No Sessions Yet",
                            systemImage: "figure.run",
                            description: Text("Create your first training session using Quick Start above")
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
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        duplicateSession(session)
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                } header: {
                    Text("My Sessions")
                } footer: {
                    if !templateSessions.isEmpty {
                        Text("Swipe left to delete, right to duplicate")
                    }
                }
            }
            .navigationTitle("Training Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        selectedTemplateType = .custom
                        showingCreateSession = true
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSession) {
                CreateSessionView(templateType: selectedTemplateType)
            }
            .navigationDestination(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
            .alert("Delete Session?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    sessionToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let session = sessionToDelete {
                        deleteSession(session)
                    }
                }
            } message: {
                Text("This will permanently delete \"\(sessionToDelete?.name ?? "this session")\". This cannot be undone.")
            }
        }
    }

    private func duplicateSession(_ session: TrainingSession) {
        let duplicate = TrainingSession(
            name: "\(session.name) (Copy)",
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
                Text(session.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(session.exerciseCount) exercises", systemImage: "list.bullet")
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
