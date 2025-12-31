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
    @State private var showingRemoveFromCalendarAlert = false
    @State private var scheduledActivitiesCount: Int = 0

    var body: some View {
        List {
            planHeaderSection
            planStatusSection
            weeksSections
            emptyStateSection
        }
        .navigationTitle(plan.localizedName)
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
        .alert("plan.sessionNotFound".localized, isPresented: $showingSessionNotFoundAlert) {
            Button("common.done".localized, role: .cancel) {}
        } message: {
            Text("plan.sessionNotFoundMessage".localized)
        }
        .sheet(isPresented: $showingEditPlan) {
            EditPlanView(plan: plan)
        }
        .sheet(isPresented: $showingSchedule) {
            SchedulePlanToCalendarSheet(plan: plan)
        }
        .alert("plans.delete".localized, isPresented: $showingDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) { deletePlan() }
        } message: {
            Text("plans.deleteConfirm".localized)
        }
        .alert("plan.resetProgressTitle".localized, isPresented: $showingResetAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("stats.reset".localized, role: .destructive) { plan.restart() }
        } message: {
            Text("plan.resetProgressMessage".localized(with: plan.localizedName))
        }
        .alert("plan.pauseTitle".localized, isPresented: $showingPauseAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("plan.pausePlan".localized) { plan.pause() }
        } message: {
            Text("plan.pauseMessage".localized)
        }
        .alert("plan.removeFromCalendar".localized, isPresented: $showingRemoveFromCalendarAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.remove".localized, role: .destructive) { removeFromCalendar() }
        } message: {
            Text("plan.removeFromCalendarMessage".localized(with: scheduledActivitiesCount))
        }
        .observeLanguageChanges()
        .onAppear { countScheduledActivities() }
    }

    // MARK: - View Components

    private var planHeaderSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if !plan.localizedDescription.isEmpty {
                    Text(plan.localizedDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 20) {
                    Label("\(plan.durationWeeks) \("plans.weeks".localized)", systemImage: "calendar")
                    Label("\(plan.targetSessionsPerWeek)x/\("plans.week".localized.lowercased())", systemImage: "repeat")
                    Label("\(plan.totalSessions) \("plans.sessions".localized)", systemImage: "list.bullet")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if plan.isActive || plan.isPaused {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ProgressView(value: plan.progressPercentage)
                            if plan.isPaused {
                                Text("plan.paused".localized)
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
                        Label("plan.startPlan".localized, systemImage: "play.fill").font(.headline)
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
                        Label("plan.pausePlan".localized, systemImage: "pause.fill").font(.headline)
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
                        Label("plan.resumePlan".localized, systemImage: "play.fill").font(.headline)
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
                        Label("plan.restartPlan".localized, systemImage: "arrow.counterclockwise").font(.headline)
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
                Text("\("plans.week".localized) \(week)")
                Spacer()
                if plan.isActive && plan.currentWeek == week {
                    Text("plan.current".localized)
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
                    Label("stats.reset".localized, systemImage: "arrow.counterclockwise")
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
                    "sessions.noSessions".localized,
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("plan.noSessionsInPlan".localized)
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { showingSchedule = true } label: {
                    Label("plan.scheduleToCalendar".localized, systemImage: "calendar.badge.clock")
                }

                if scheduledActivitiesCount > 0 {
                    Button {
                        showingRemoveFromCalendarAlert = true
                    } label: {
                        Label("plan.removeFromCalendar".localized, systemImage: "calendar.badge.minus")
                    }
                }

                Button { showingEditPlan = true } label: {
                    Label("plan.editPlan".localized, systemImage: "pencil")
                }

                if plan.isActive || plan.isFinished {
                    Button { showingResetAlert = true } label: {
                        Label("plan.resetProgress".localized, systemImage: "arrow.counterclockwise")
                    }
                }

                Divider()

                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("plan.deletePlan".localized, systemImage: "trash")
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
        let planId = plan.id

        // Find all scheduled activities linked to this plan
        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate<ScheduledActivity> { $0.linkedPlanId == planId }
        )

        if let activities = try? modelContext.fetch(descriptor) {
            // Collect calendar event IDs to delete from phone calendar
            let eventIds = activities.compactMap { $0.calendarEventId }

            // Delete from phone calendar first, then from SwiftData
            Task {
                await CalendarService.shared.deleteEvents(eventIdentifiers: eventIds)

                await MainActor.run {
                    for activity in activities {
                        modelContext.delete(activity)
                    }
                    modelContext.delete(plan)
                    dismiss()
                }
            }
        } else {
            // No activities to delete, just delete the plan
            modelContext.delete(plan)
            dismiss()
        }
    }

    private func countScheduledActivities() {
        let planId = plan.id
        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate<ScheduledActivity> { $0.linkedPlanId == planId }
        )
        scheduledActivitiesCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func removeFromCalendar() {
        let planId = plan.id
        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate<ScheduledActivity> { $0.linkedPlanId == planId }
        )

        guard let activities = try? modelContext.fetch(descriptor) else { return }

        // Collect all calendar event IDs to delete
        let eventIds = activities.compactMap { $0.calendarEventId }

        // Delete from device calendar first, then from SwiftData
        Task {
            // Delete all calendar events
            await CalendarService.shared.deleteEvents(eventIdentifiers: eventIds)

            // Then delete from SwiftData on main actor
            await MainActor.run {
                for activity in activities {
                    modelContext.delete(activity)
                }
                scheduledActivitiesCount = 0
            }
        }
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
                    Text(planSession.localizedSessionName)
                        .font(.headline)
                        .foregroundStyle(planSession.isCompleted ? .secondary : .primary)
                        .strikethrough(planSession.isCompleted)

                    if let completedDate = planSession.completedDateFormatted {
                        Text("plan.completedDate".localized(with: completedDate))
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else if isCurrentWeek && !planSession.isCompleted {
                        Text("plan.readyToStart".localized)
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
                Section("plan.planDetails".localized) {
                    TextField("profile.name".localized, text: $name)

                    TextField("exercise.description".localized, text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("sessions.schedule".localized) {
                    Stepper("plan.durationWeeks".localized(with: durationWeeks), value: $durationWeeks, in: 1...52)

                    Stepper("plan.sessionsPerWeek".localized(with: sessionsPerWeek), value: $sessionsPerWeek, in: 1...7)
                }

                Section {
                    Text("plan.sessionsInPlan".localized(with: plan.sessions.count))
                        .foregroundStyle(.secondary)
                } footer: {
                    Text("plan.modifySessionsHint".localized)
                }
            }
            .navigationTitle("plan.editPlan".localized)
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
                        savePlan()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadPlanData()
            }
            .observeLanguageChanges()
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
                Section("plans.title".localized) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.blue)
                        Text(plan.localizedName)
                            .fontWeight(.medium)
                    }

                    LabeledContent("training.duration".localized, value: "\(plan.durationWeeks) \("plans.weeks".localized)")
                    LabeledContent("plans.sessions".localized, value: "\(plan.sessions.count)")
                }

                Section("sessions.schedule".localized) {
                    DatePicker("plan.startDate".localized, selection: $startDate, in: Date()..., displayedComponents: .date)
                    DatePicker("plan.trainingTime".localized, selection: $scheduledTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    Toggle("detail.remindMe".localized, isOn: $enableNotifications)

                    if enableNotifications {
                        Picker("detail.reminder".localized, selection: $notificationMinutes) {
                            Text("detail.15min".localized).tag(15)
                            Text("detail.30min".localized).tag(30)
                            Text("detail.1hour".localized).tag(60)
                        }
                    }
                } header: {
                    Text("profile.notifications".localized)
                } footer: {
                    Text("plan.scheduleFooter".localized)
                }
            }
            .navigationTitle("plans.schedule".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("sessions.schedule".localized) {
                        schedulePlan()
                        dismiss()
                    }
                }
            }
            .observeLanguageChanges()
        }
    }

    private func schedulePlan() {
        // Start the plan so it shows as active
        plan.start()

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

                // Create the activity with localized names
                let activity = ScheduledActivity(
                    title: session.localizedSessionName,
                    type: .training,
                    scheduledDate: sessionDate,
                    durationMinutes: 60,
                    notes: "\("plan.partOf".localized): \(plan.localizedName) - \("plans.week".localized) \(weekNumber)"
                )
                activity.linkedSessionId = session.sessionId
                activity.linkedSessionName = session.localizedSessionName
                activity.linkedPlanId = plan.id

                modelContext.insert(activity)

                // Sync to device calendar (calendar alarms replace app notifications)
                if enableNotifications {
                    Task {
                        if let eventId = await CalendarService.shared.createEvent(
                            for: activity,
                            reminderMinutes: notificationMinutes
                        ) {
                            activity.calendarEventId = eventId
                        }
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
