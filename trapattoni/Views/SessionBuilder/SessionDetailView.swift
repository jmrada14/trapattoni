import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var plans: [TrainingPlan]
    @Bindable var session: TrainingSession

    @State private var showingExecution = false
    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var showingAddExercise = false
    @State private var showingAddToPlan = false
    @State private var showingSchedule = false

    private var activePlans: [TrainingPlan] {
        plans.filter { !$0.isPrebuilt && !$0.isFinished }
    }

    var body: some View {
        List {
            // Header Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: session.templateType.iconName)
                            .font(.title)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading) {
                            Text(session.templateType.localizedName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.localizedName)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }

                    if !session.localizedDescription.isEmpty {
                        Text(session.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Label("\(session.exerciseCount) \("sessions.exercises".localized)", systemImage: "list.bullet")
                        Label(session.totalDurationFormatted, systemImage: "clock")
                        Label("\(session.defaultRestSeconds)s \("session.rest".localized.lowercased())", systemImage: "pause.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // Start Button
            Section {
                Button {
                    showingExecution = true
                } label: {
                    HStack {
                        Spacer()
                        Label("session.startSession".localized, systemImage: "play.fill")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .disabled(session.exercises.isEmpty)
            }

            // Exercises Section
            Section {
                if session.exercises.isEmpty {
                    ContentUnavailableView(
                        "sessions.noExercisesYet".localized,
                        systemImage: "figure.run",
                        description: Text("sessions.tapToAdd".localized)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(session.sortedExercises) { exercise in
                        SessionExerciseRow(exercise: exercise)
                    }
                    .onDelete(perform: deleteExercises)
                    .onMove(perform: moveExercises)
                }

                Button {
                    showingAddExercise = true
                } label: {
                    Label("exercise.add".localized, systemImage: "plus.circle")
                }
            } header: {
                HStack {
                    Text("training.exercises".localized)
                    Spacer()
                    #if os(iOS)
                    if !session.exercises.isEmpty {
                        EditButton()
                            .font(.caption)
                    }
                    #endif
                }
            }
        }
        .navigationTitle(session.localizedName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingSchedule = true
                    } label: {
                        Label("sessions.schedule".localized, systemImage: "calendar.badge.clock")
                    }

                    Button {
                        showingEdit = true
                    } label: {
                        Label("detail.editDetails".localized, systemImage: "pencil")
                    }

                    Button {
                        duplicateSession()
                    } label: {
                        Label("sessions.duplicate".localized, systemImage: "doc.on.doc")
                    }

                    Button {
                        showingAddToPlan = true
                    } label: {
                        Label("detail.addToPlan".localized, systemImage: "list.bullet.rectangle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("sessions.delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showingExecution) {
            SessionExecutionView(session: session)
        }
        #else
        .sheet(isPresented: $showingExecution) {
            SessionExecutionView(session: session)
                .frame(minWidth: 600, minHeight: 500)
        }
        #endif
        .sheet(isPresented: $showingEdit) {
            EditSessionView(session: session)
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseToSessionView(session: session)
        }
        .sheet(isPresented: $showingAddToPlan) {
            AddSessionToPlanSheet(session: session, plans: activePlans)
        }
        .sheet(isPresented: $showingSchedule) {
            ScheduleSessionSheet(session: session)
        }
        .alert("sessions.delete".localized, isPresented: $showingDeleteAlert) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("sessions.deleteConfirm".localized)
        }
        .observeLanguageChanges()
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = session.sortedExercises
        for index in offsets {
            if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == sorted[index].id }) {
                session.exercises.remove(at: exerciseIndex)
            }
        }
        session.updatedAt = Date()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var exercises = session.sortedExercises
        exercises.move(fromOffsets: source, toOffset: destination)
        session.reorderExercises(exercises)
        session.updatedAt = Date()
    }

    private func duplicateSession() {
        let duplicate = TrainingSession(
            name: "\(session.localizedName) (Copy)",
            description: session.sessionDescription,
            templateType: session.templateType
        )
        duplicate.defaultRestSeconds = session.defaultRestSeconds
        duplicate.isTemplate = true

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

    private func deleteSession() {
        modelContext.delete(session)
        dismiss()
    }
}

// MARK: - Session Exercise Row

struct SessionExerciseRow: View {
    let exercise: SessionExercise

    var body: some View {
        HStack(spacing: 12) {
            Text("\(exercise.orderIndex + 1)")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            CategoryIconView(category: exercise.exerciseCategory, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(exercise.durationFormatted)
                    if exercise.restAfterSeconds > 0 {
                        Text("•")
                        Text(exercise.restFormatted)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Session View

struct EditSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: TrainingSession

    var body: some View {
        NavigationStack {
            Form {
                Section("sessions.title".localized) {
                    TextField("profile.name".localized, text: $session.name)

                    TextField("exercise.description".localized, text: $session.sessionDescription, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("exercise.trainingType".localized, selection: $session.templateType) {
                        ForEach(SessionTemplateType.allCases) { type in
                            Label(type.localizedName, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Stepper("\("sessions.restTime".localized): \(session.defaultRestSeconds)s", value: $session.defaultRestSeconds, in: 0...120, step: 15)
                }

                Section("\("training.exercises".localized) (\(session.exerciseCount))") {
                    if session.exercises.isEmpty {
                        Text("sessions.noExercisesYet".localized)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(session.sortedExercises) { exercise in
                            HStack {
                                Text("\(exercise.orderIndex + 1).")
                                    .foregroundStyle(.secondary)
                                Text(exercise.exerciseName)
                                Spacer()
                                Text(exercise.durationFormatted)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onMove { source, destination in
                            var exercises = session.sortedExercises
                            exercises.move(fromOffsets: source, toOffset: destination)
                            session.reorderExercises(exercises)
                        }
                        .onDelete { offsets in
                            let sorted = session.sortedExercises
                            for index in offsets {
                                if let exerciseIndex = session.exercises.firstIndex(where: { $0.id == sorted[index].id }) {
                                    session.exercises.remove(at: exerciseIndex)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("common.edit".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done".localized) {
                        session.updatedAt = Date()
                        dismiss()
                    }
                }

                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                #endif
            }
            .observeLanguageChanges()
        }
    }
}

// MARK: - Add Session to Plan Sheet

struct AddSessionToPlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: TrainingSession
    let plans: [TrainingPlan]

    @State private var selectedPlan: TrainingPlan?
    @State private var weekNumber: Int = 1
    @State private var showingCreatePlan = false

    var body: some View {
        NavigationStack {
            Form {
                if plans.isEmpty {
                    Section {
                        ContentUnavailableView(
                            "detail.noPlans".localized,
                            systemImage: "calendar",
                            description: Text("detail.createPlanFirst".localized)
                        )
                    }
                } else {
                    Section("detail.selectPlan".localized) {
                        ForEach(plans) { plan in
                            Button {
                                selectedPlan = plan
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.localizedName)
                                            .foregroundStyle(.primary)
                                        Text("\(plan.durationWeeks) \("plans.weeks".localized) • \(plan.totalSessions) \("plans.sessions".localized)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedPlan?.id == plan.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let plan = selectedPlan {
                        Section("plans.week".localized) {
                            Picker("detail.addToWeek".localized, selection: $weekNumber) {
                                ForEach(1...plan.durationWeeks, id: \.self) { week in
                                    Text("\("plans.week".localized) \(week)").tag(week)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }

                Section {
                    NavigationLink {
                        CreatePlanView()
                    } label: {
                        Label("detail.createNewPlan".localized, systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("detail.addToPlan".localized)
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
                    Button("common.add".localized) {
                        addToPlan()
                    }
                    .disabled(selectedPlan == nil)
                }
            }
            .observeLanguageChanges()
        }
    }

    private func addToPlan() {
        guard let plan = selectedPlan else { return }

        // Find the next order index for this week
        let sessionsInWeek = plan.sessions.filter { $0.weekNumber == weekNumber }
        let nextOrder = (sessionsInWeek.map(\.orderInWeek).max() ?? 0) + 1

        plan.addSession(session, weekNumber: weekNumber, orderInWeek: nextOrder)
        plan.updatedAt = Date()
        dismiss()
    }
}

// MARK: - Schedule Session Sheet

struct ScheduleSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let session: TrainingSession

    @State private var scheduledDate: Date = Date()
    @State private var enableNotification: Bool = true
    @State private var notificationMinutes: Int = 15
    @State private var recurrenceType: RecurrenceType = .none
    @State private var recurrenceEndDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()

    private var recurrenceCount: Int {
        guard recurrenceType != .none,
              let component = recurrenceType.calendarComponent else { return 1 }

        let calendar = Calendar.current
        var count = 0
        var currentDate = scheduledDate

        while currentDate <= recurrenceEndDate {
            count += 1
            if let nextDate = calendar.date(byAdding: component, value: recurrenceType.componentValue, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        return count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("tab.sessions".localized) {
                    HStack {
                        Image(systemName: session.templateType.iconName)
                            .foregroundStyle(.blue)
                        Text(session.localizedName)
                            .fontWeight(.medium)
                    }

                    LabeledContent("training.duration".localized, value: session.totalDurationFormatted)
                    LabeledContent("training.exercises".localized, value: "\(session.exerciseCount)")
                }

                Section("sessions.schedule".localized) {
                    DatePicker("detail.dateTime".localized, selection: $scheduledDate, in: Date()...)
                }

                Section {
                    Picker("detail.repeat".localized, selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if recurrenceType != .none {
                        DatePicker("detail.until".localized, selection: $recurrenceEndDate, in: scheduledDate..., displayedComponents: .date)

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("detail.willSchedule".localized(with: recurrenceCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("detail.recurrence".localized)
                }

                Section {
                    Toggle("detail.remindMe".localized, isOn: $enableNotification)

                    if enableNotification {
                        Picker("detail.reminder".localized, selection: $notificationMinutes) {
                            Text("detail.15min".localized).tag(15)
                            Text("detail.30min".localized).tag(30)
                            Text("detail.1hour".localized).tag(60)
                            Text("detail.2hours".localized).tag(120)
                        }
                    }
                } header: {
                    Text("detail.notification".localized)
                } footer: {
                    if enableNotification {
                        Text("detail.notificationFooter".localized)
                    }
                }
            }
            .navigationTitle("sessions.schedule".localized)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("sessions.schedule".localized) {
                        scheduleSession()
                        dismiss()
                    }
                }
            }
            .observeLanguageChanges()
        }
    }

    private func scheduleSession() {
        let calendar = Calendar.current
        let groupId: UUID? = recurrenceType != .none ? UUID() : nil

        // Generate dates
        var dates: [Date] = []
        if recurrenceType == .none {
            dates = [scheduledDate]
        } else if let component = recurrenceType.calendarComponent {
            var currentDate = scheduledDate
            while currentDate <= recurrenceEndDate {
                dates.append(currentDate)
                if let nextDate = calendar.date(byAdding: component, value: recurrenceType.componentValue, to: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }
        }

        // Track created activities for calendar sync
        var createdActivities: [ScheduledActivity] = []

        // Create activities
        for date in dates {
            let activity = ScheduledActivity(session: session, scheduledDate: date)
            activity.recurrenceType = recurrenceType
            activity.recurrenceGroupId = groupId
            if recurrenceType != .none {
                activity.recurrenceEndDate = recurrenceEndDate
            }

            modelContext.insert(activity)
            createdActivities.append(activity)
        }

        // Sync to device calendar (calendar alarms replace app notifications)
        if enableNotification {
            Task {
                if recurrenceType != .none, let firstActivity = createdActivities.first {
                    // Create single recurring event in calendar
                    if let eventId = await CalendarService.shared.createRecurringEvent(
                        for: firstActivity,
                        recurrenceType: recurrenceType,
                        endDate: recurrenceEndDate,
                        reminderMinutes: notificationMinutes
                    ) {
                        // Store same event ID in all activities
                        for activity in createdActivities {
                            activity.calendarEventId = eventId
                        }
                    }
                } else {
                    // Create individual events for non-recurring activities
                    for activity in createdActivities {
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
        SessionDetailView(session: TrainingSession(
            name: "Morning Warmup",
            description: "Quick warmup routine",
            templateType: .warmUp
        ))
    }
    .modelContainer(for: TrainingSession.self, inMemory: true)
}
