import SwiftUI
import SwiftData

struct CreatePlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<TrainingSession> { $0.isTemplate },
        sort: \TrainingSession.name
    )
    private var availableSessions: [TrainingSession]

    @State private var name = ""
    @State private var description = ""
    @State private var durationWeeks = 4
    @State private var sessionsPerWeek = 3
    @State private var weekSessions: [[TrainingSession]] = []

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        weekSessions.contains { !$0.isEmpty }
    }

    private var totalSessions: Int {
        weekSessions.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Plan Details
                Section("Plan Details") {
                    TextField("Plan Name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)

                    Stepper("Duration: \(durationWeeks) weeks", value: $durationWeeks, in: 1...12)
                        .onChange(of: durationWeeks) {
                            adjustWeekSessions()
                        }

                    Stepper("Target: \(sessionsPerWeek)x per week", value: $sessionsPerWeek, in: 1...7)
                }

                // Sessions Per Week
                ForEach(1...durationWeeks, id: \.self) { week in
                    Section {
                        let weekIndex = week - 1

                        if weekIndex < weekSessions.count {
                            ForEach(weekSessions[weekIndex], id: \.id) { session in
                                HStack {
                                    Image(systemName: session.templateType.iconName)
                                        .foregroundStyle(.blue)

                                    Text(session.name)

                                    Spacer()

                                    Button {
                                        removeSession(session, from: week)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if availableSessions.isEmpty {
                            Text("Create some training sessions first")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Menu {
                                ForEach(availableSessions) { session in
                                    Button {
                                        addSession(session, to: week)
                                    } label: {
                                        Label(session.name, systemImage: session.templateType.iconName)
                                    }
                                }
                            } label: {
                                Label("Add Session", systemImage: "plus.circle")
                            }
                        }
                    } header: {
                        HStack {
                            Text("Week \(week)")
                            Spacer()
                            if (week - 1) < weekSessions.count && !weekSessions[week - 1].isEmpty {
                                Text("\(weekSessions[week - 1].count) session\(weekSessions[week - 1].count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Summary
                if totalSessions > 0 {
                    Section {
                        LabeledContent("Total Sessions") {
                            Text("\(totalSessions)")
                        }

                        LabeledContent("Avg. per Week") {
                            Text(String(format: "%.1f", Double(totalSessions) / Double(durationWeeks)))
                        }
                    } header: {
                        Text("Summary")
                    }
                }
            }
            .navigationTitle("New Plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { savePlan() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                initializeWeekSessions()
            }
        }
    }

    private func initializeWeekSessions() {
        weekSessions = Array(repeating: [], count: durationWeeks)
    }

    private func adjustWeekSessions() {
        while weekSessions.count < durationWeeks {
            weekSessions.append([])
        }
        if weekSessions.count > durationWeeks {
            weekSessions = Array(weekSessions.prefix(durationWeeks))
        }
    }

    private func addSession(_ session: TrainingSession, to week: Int) {
        let weekIndex = week - 1
        guard weekIndex < weekSessions.count else { return }
        weekSessions[weekIndex].append(session)
    }

    private func removeSession(_ session: TrainingSession, from week: Int) {
        let weekIndex = week - 1
        guard weekIndex < weekSessions.count else { return }
        weekSessions[weekIndex].removeAll { $0.id == session.id }
    }

    private func savePlan() {
        let plan = TrainingPlan(
            name: name.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            durationWeeks: durationWeeks,
            targetSessionsPerWeek: sessionsPerWeek,
            isPrebuilt: false
        )

        modelContext.insert(plan)

        // Add sessions to the plan
        for (weekIndex, sessions) in weekSessions.enumerated() {
            for (orderIndex, session) in sessions.enumerated() {
                plan.addSession(session, weekNumber: weekIndex + 1, orderInWeek: orderIndex + 1)
            }
        }

        dismiss()
    }
}

#Preview {
    CreatePlanView()
        .modelContainer(for: [TrainingPlan.self, TrainingSession.self], inMemory: true)
}
