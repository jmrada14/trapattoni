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
                            Text(session.templateType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }

                    if !session.sessionDescription.isEmpty {
                        Text(session.sessionDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 16) {
                        Label("\(session.exerciseCount) exercises", systemImage: "list.bullet")
                        Label(session.totalDurationFormatted, systemImage: "clock")
                        Label("\(session.defaultRestSeconds)s rest", systemImage: "pause.circle")
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
                        Label("Start Session", systemImage: "play.fill")
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
                        "No Exercises",
                        systemImage: "figure.run",
                        description: Text("Tap Edit to add exercises to this session")
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
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            } header: {
                HStack {
                    Text("Exercises")
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
        .navigationTitle(session.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingSchedule = true
                    } label: {
                        Label("Schedule", systemImage: "calendar.badge.clock")
                    }

                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Details", systemImage: "pencil")
                    }

                    Button {
                        duplicateSession()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }

                    Button {
                        showingAddToPlan = true
                    } label: {
                        Label("Add to Plan", systemImage: "list.bullet.rectangle")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Session", systemImage: "trash")
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
        .alert("Delete Session?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteSession()
            }
        } message: {
            Text("This will permanently delete \"\(session.name)\". This cannot be undone.")
        }
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
            name: "\(session.name) (Copy)",
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
                Section("Session Details") {
                    TextField("Name", text: $session.name)

                    TextField("Description", text: $session.sessionDescription, axis: .vertical)
                        .lineLimit(2...4)

                    Picker("Type", selection: $session.templateType) {
                        ForEach(SessionTemplateType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }

                    Stepper("Rest: \(session.defaultRestSeconds)s", value: $session.defaultRestSeconds, in: 0...120, step: 15)
                }

                Section("Exercises (\(session.exerciseCount))") {
                    if session.exercises.isEmpty {
                        Text("No exercises added yet")
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
            .navigationTitle("Edit Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
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
                            "No Plans",
                            systemImage: "calendar",
                            description: Text("Create a training plan first to add sessions")
                        )
                    }
                } else {
                    Section("Select Plan") {
                        ForEach(plans) { plan in
                            Button {
                                selectedPlan = plan
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(plan.name)
                                            .foregroundStyle(.primary)
                                        Text("\(plan.durationWeeks) weeks • \(plan.totalSessions) sessions")
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
                        Section("Week") {
                            Picker("Add to Week", selection: $weekNumber) {
                                ForEach(1...plan.durationWeeks, id: \.self) { week in
                                    Text("Week \(week)").tag(week)
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
                        Label("Create New Plan", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Add to Plan")
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
                    Button("Add") {
                        addToPlan()
                    }
                    .disabled(selectedPlan == nil)
                }
            }
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
                Section("Session") {
                    HStack {
                        Image(systemName: session.templateType.iconName)
                            .foregroundStyle(.blue)
                        Text(session.name)
                            .fontWeight(.medium)
                    }

                    LabeledContent("Duration", value: session.totalDurationFormatted)
                    LabeledContent("Exercises", value: "\(session.exerciseCount)")
                }

                Section("Schedule") {
                    DatePicker("Date & Time", selection: $scheduledDate, in: Date()...)
                }

                Section {
                    Picker("Repeat", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if recurrenceType != .none {
                        DatePicker("Until", selection: $recurrenceEndDate, in: scheduledDate..., displayedComponents: .date)

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Will schedule \(recurrenceCount) sessions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Recurrence")
                }

                Section {
                    Toggle("Remind me", isOn: $enableNotification)

                    if enableNotification {
                        Picker("Reminder", selection: $notificationMinutes) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                            Text("2 hours before").tag(120)
                        }
                    }
                } header: {
                    Text("Notification")
                } footer: {
                    if enableNotification {
                        Text("You'll receive a notification before each scheduled session")
                    }
                }
            }
            .navigationTitle("Schedule Session")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        scheduleSession()
                        dismiss()
                    }
                }
            }
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

        // Create activities
        for date in dates {
            let activity = ScheduledActivity(session: session, scheduledDate: date)
            activity.recurrenceType = recurrenceType
            activity.recurrenceGroupId = groupId
            if recurrenceType != .none {
                activity.recurrenceEndDate = recurrenceEndDate
            }

            modelContext.insert(activity)

            // Schedule notification
            if enableNotification {
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
