import SwiftUI
import SwiftData

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSessions: [TrainingSession]

    @Bindable var plan: TrainingPlan

    @State private var sessionToExecute: TrainingSession?
    @State private var planSessionToComplete: PlanSession?
    @State private var showingEditPlan = false
    @State private var showingDeleteAlert = false
    @State private var showingResetAlert = false
    @State private var showingPauseAlert = false
    @State private var showingSessionNotFoundAlert = false
    @State private var showingSchedule = false

    var body: some View {
        List {
            planHeaderSection
            planStatusSection
            weeksSections
            emptyStateSection
        }
        .navigationTitle(plan.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        #if os(iOS)
        .fullScreenCover(item: $sessionToExecute) { session in
            SessionExecutionView(session: session, planId: plan.id)
                .onDisappear { handleSessionDismiss() }
        }
        #else
        .sheet(item: $sessionToExecute) { session in
            SessionExecutionView(session: session, planId: plan.id)
                .frame(minWidth: 600, minHeight: 500)
                .onDisappear { handleSessionDismiss() }
        }
        #endif
        .alert("Session Not Found", isPresented: $showingSessionNotFoundAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The training session for this plan could not be found. It may have been deleted.")
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanView(plan: plan)
        }
        .sheet(isPresented: $showingSchedule) {
            SchedulePlanToCalendarSheet(plan: plan)
        }
        .alert("Delete Plan?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deletePlan() }
        } message: {
            Text("This will permanently delete \"\(plan.name)\". This cannot be undone.")
        }
        .alert("Reset Progress?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { plan.restart() }
        } message: {
            Text("This will reset all progress for \"\(plan.name)\". All completed sessions will be marked as incomplete.")
        }
        .alert("Pause Plan?", isPresented: $showingPauseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Pause") { plan.pause() }
        } message: {
            Text("This will pause the plan. Your progress will be preserved and you can resume anytime.")
        }
    }

    // MARK: - View Components

    private var planHeaderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if !plan.planDescription.isEmpty {
                    Text(plan.planDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 20) {
                    Label("\(plan.durationWeeks) weeks", systemImage: "calendar")
                    Label("\(plan.targetSessionsPerWeek)x/week", systemImage: "repeat")
                    Label("\(plan.totalSessions) sessions", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if plan.isActive || plan.isPaused {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ProgressView(value: plan.progressPercentage)
                            if plan.isPaused {
                                Text("PAUSED")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(plan.progressFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var planStatusSection: some View {
        if plan.isNotStarted {
            Section {
                Button { startPlan() } label: {
                    HStack {
                        Spacer()
                        Label("Start Plan", systemImage: "play.fill").font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        } else if plan.isActive {
            Section {
                Button { showingPauseAlert = true } label: {
                    HStack {
                        Spacer()
                        Label("Pause Plan", systemImage: "pause.fill").font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .foregroundStyle(.orange)
            }
        } else if plan.isPaused {
            Section {
                Button { plan.resume() } label: {
                    HStack {
                        Spacer()
                        Label("Resume Plan", systemImage: "play.fill").font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        } else if plan.isFinished {
            Section {
                Button { showingResetAlert = true } label: {
                    HStack {
                        Spacer()
                        Label("Restart Plan", systemImage: "arrow.counterclockwise").font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .foregroundStyle(.green)
            }
        }
    }

    private var weeksSections: some View {
        ForEach(plan.sessionsByWeek, id: \.week) { weekData in
            weekSection(week: weekData.week, sessions: weekData.sessions)
        }
    }

    private func weekSection(week: Int, sessions: [PlanSession]) -> some View {
        Section {
            ForEach(sessions) { planSession in
                planSessionRow(planSession: planSession, week: week)
            }
        } header: {
            HStack {
                Text("Week \(week)")
                Spacer()
                if plan.isActive && plan.currentWeek == week {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func planSessionRow(planSession: PlanSession, week: Int) -> some View {
        PlanSessionRowView(
            planSession: planSession,
            isCurrentWeek: plan.isActive && plan.currentWeek == week,
            isEnabled: plan.isActive && !planSession.isCompleted
        ) {
            if let session = allSessions.first(where: { $0.id == planSession.sessionId }) {
                planSessionToComplete = planSession
                sessionToExecute = session
            } else {
                showingSessionNotFoundAlert = true
            }
        }
        .swipeActions(edge: .leading) {
            if planSession.isCompleted {
                Button { planSession.resetCompletion() } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .tint(.orange)
            }
        }
    }

    @ViewBuilder
    private var emptyStateSection: some View {
        if plan.sessions.isEmpty {
            Section {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("This plan doesn't have any sessions yet")
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { showingSchedule = true } label: {
                    Label("Schedule to Calendar", systemImage: "calendar.badge.clock")
                }

                Button { showingEditPlan = true } label: {
                    Label("Edit Plan", systemImage: "pencil")
                }

                if plan.isActive || plan.isFinished {
                    Button { showingResetAlert = true } label: {
                        Label("Reset Progress", systemImage: "arrow.counterclockwise")
                    }
                }

                Divider()

                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("Delete Plan", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func handleSessionDismiss() {
        if let planSession = planSessionToComplete {
            checkAndMarkCompletion(for: planSession)
        }
    }

    // MARK: - Methods

    private func checkAndMarkCompletion(for planSession: PlanSession) {
        // The session execution view will create a log with the plan ID
        // We can query for it to mark completion
        let planIdToMatch = plan.id
        let descriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate<SessionLog> { log in
                log.planId == planIdToMatch && log.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )

        if let logs = try? modelContext.fetch(descriptor),
           let latestLog = logs.first,
           !planSession.isCompleted {
            planSession.markCompleted(with: latestLog)
        }
    }

    private func deletePlan() {
        // Get all session IDs from the plan before deleting
        let sessionIds = plan.sessions.map { $0.sessionId }

        // Delete associated calendar events
        for sessionId in sessionIds {
            let descriptor = FetchDescriptor<ScheduledActivity>(
                predicate: #Predicate<ScheduledActivity> { $0.linkedSessionId == sessionId }
            )
            if let activities = try? modelContext.fetch(descriptor) {
                for activity in activities {
                    modelContext.delete(activity)
                }
            }
        }

        modelContext.delete(plan)
        dismiss()
    }

    private func startPlan() {
        if plan.isPrebuilt {
            // Create a copy of prebuilt plans so the original stays as a template
            let copy = TrainingPlan(
                name: plan.name,
                description: plan.planDescription,
                durationWeeks: plan.durationWeeks,
                targetSessionsPerWeek: plan.targetSessionsPerWeek,
                isPrebuilt: false
            )

            // Copy all sessions
            for session in plan.sessions {
                let sessionCopy = PlanSession(
                    sessionId: session.sessionId,
                    sessionName: session.sessionName,
                    week: session.weekNumber,
                    dayOfWeek: 0,
                    orderIndex: session.orderInWeek
                )
                copy.sessions.append(sessionCopy)
            }

            modelContext.insert(copy)
            copy.start()
            dismiss() // Go back to list so user can see the new active plan
        } else {
            plan.start()
        }
    }
}

// MARK: - Plan Session Row View

struct PlanSessionRowView: View {
    let planSession: PlanSession
    let isCurrentWeek: Bool
    let isEnabled: Bool
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            HStack(spacing: 12) {
                // Status indicator
                Image(systemName: planSession.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(planSession.isCompleted ? .green : isCurrentWeek ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(planSession.sessionName)
                        .font(.headline)
                        .foregroundStyle(planSession.isCompleted ? .secondary : .primary)
                        .strikethrough(planSession.isCompleted)

                    if let completedDate = planSession.completedDateFormatted {
                        Text("Completed \(completedDate)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if isCurrentWeek && !planSession.isCompleted {
                        Text("Ready to start")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer()

                if !planSession.isCompleted && isEnabled {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || planSession.isCompleted)
    }
}

// MARK: - Edit Plan View

struct EditPlanView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var plan: TrainingPlan

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var durationWeeks: Int = 4
    @State private var sessionsPerWeek: Int = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan Details") {
                    TextField("Name", text: $name)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Schedule") {
                    Stepper("Duration: \(durationWeeks) weeks", value: $durationWeeks, in: 1...52)

                    Stepper("Sessions per week: \(sessionsPerWeek)", value: $sessionsPerWeek, in: 1...7)
                }

                Section {
                    Text("Sessions in plan: \(plan.sessions.count)")
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("To modify sessions, create a new plan or use duplicate")
                }
            }
            .navigationTitle("Edit Plan")
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
                        savePlan()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadPlanData()
            }
        }
    }

    private func loadPlanData() {
        name = plan.name
        description = plan.planDescription
        durationWeeks = plan.durationWeeks
        sessionsPerWeek = plan.targetSessionsPerWeek
    }

    private func savePlan() {
        plan.name = name
        plan.planDescription = description
        plan.durationWeeks = durationWeeks
        plan.targetSessionsPerWeek = sessionsPerWeek
        plan.updatedAt = Date()
    }
}

// MARK: - Schedule Plan to Calendar Sheet

struct SchedulePlanToCalendarSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let plan: TrainingPlan

    @State private var startDate: Date = Date()
    @State private var scheduledTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var enableNotifications: Bool = true
    @State private var notificationMinutes: Int = 15

    var body: some View {
        NavigationStack {
            Form {
                Section("Plan") {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.blue)
                        Text(plan.name)
                            .fontWeight(.medium)
                    }

                    LabeledContent("Duration", value: "\(plan.durationWeeks) weeks")
                    LabeledContent("Sessions", value: "\(plan.sessions.count)")
                }

                Section("Schedule") {
                    DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                    DatePicker("Training Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    Toggle("Remind me", isOn: $enableNotifications)

                    if enableNotifications {
                        Picker("Reminder", selection: $notificationMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Sessions will be scheduled throughout each week starting from your selected date")
                }
            }
            .navigationTitle("Schedule Plan")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        schedulePlan()
                        dismiss()
                    }
                }
            }
        }
    }

    private func schedulePlan() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        // Sort sessions by week and order
        let sortedSessions = plan.sessions.sorted { first, second in
            if first.weekNumber != second.weekNumber {
                return first.weekNumber < second.weekNumber
            }
            return first.orderInWeek < second.orderInWeek
        }

        // Group sessions by week
        let sessionsByWeek = Dictionary(grouping: sortedSessions) { $0.weekNumber }

        for (weekNumber, weekSessions) in sessionsByWeek {
            for (index, session) in weekSessions.enumerated() {
                // Calculate the date for this session
                let weekOffset = weekNumber - 1
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate) else { continue }

                // Space sessions evenly through the week
                let daysToAdd = index * (7 / max(weekSessions.count, 1))
                guard var sessionDate = calendar.date(byAdding: .day, value: daysToAdd, to: weekStart) else { continue }

                // Set the time
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: sessionDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                sessionDate = calendar.date(from: dateComponents) ?? sessionDate

                // Create the activity
                let activity = ScheduledActivity(
                    title: session.sessionName,
                    type: .training,
                    scheduledDate: sessionDate,
                    durationMinutes: 60,
                    notes: "Part of plan: \(plan.name) - Week \(weekNumber)"
                )
                activity.linkedSessionId = session.sessionId
                activity.linkedSessionName = session.sessionName

                modelContext.insert(activity)

                // Schedule notification
                if enableNotifications {
                    Task {
                        await NotificationService.shared.scheduleActivityReminder(
                            for: activity,
                            minutesBefore: notificationMinutes
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlanDetailView(plan: TrainingPlan(
            name: "Beginner Fundamentals",
            description: "Build a strong foundation with basic skills",
            durationWeeks: 4,
            targetSessionsPerWeek: 3
        ))
    }
    .modelContainer(for: [TrainingPlan.self, TrainingSession.self], inMemory: true)
}
