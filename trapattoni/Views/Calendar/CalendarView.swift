import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ScheduledActivity.scheduledDate)
    private var activities: [ScheduledActivity]
    @Query(sort: \SessionLog.completedAt, order: .reverse)
    private var sessionLogs: [SessionLog]
    @Query private var sessions: [TrainingSession]
    @Query private var plans: [TrainingPlan]

    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingAddActivity = false
    @State private var showingSchedulePlan = false
    @State private var selectedActivity: ScheduledActivity?

    private let calendar = Calendar.current

    private var activitiesForSelectedDate: [ScheduledActivity] {
        activities.filter { calendar.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
    }

    private var sessionsCompletedOnSelectedDate: [SessionLog] {
        sessionLogs.filter {
            guard let completedAt = $0.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: selectedDate)
        }
    }

    private var templateSessions: [TrainingSession] {
        sessions.filter { $0.isTemplate }
    }

    private var upcomingTodayActivities: [ScheduledActivity] {
        let now = Date()
        return activities.filter { activity in
            calendar.isDateInToday(activity.scheduledDate) &&
            activity.scheduledDate > now &&
            !activity.isCompleted
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private var upcomingThisWeekActivities: [ScheduledActivity] {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: Date()) else { return [] }
        let now = Date()
        return activities.filter { activity in
            activity.scheduledDate > now &&
            activity.scheduledDate <= weekEnd &&
            !activity.isCompleted &&
            !calendar.isDateInToday(activity.scheduledDate)
        }.sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private var isTodaySelected: Bool {
        calendar.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Coming Up This Week (only show when today is selected)
                    if isTodaySelected && !upcomingThisWeekActivities.isEmpty {
                        upcomingThisWeekSection
                    }

                    // Calendar Grid
                    calendarHeader
                    calendarGrid

                    // Selected Date Activities (includes today's activities when today is selected)
                    selectedDateSection
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingAddActivity = true
                        } label: {
                            Label("Add Activity", systemImage: "plus")
                        }

                        if !plans.isEmpty {
                            Button {
                                showingSchedulePlan = true
                            } label: {
                                Label("Schedule Plan", systemImage: "list.bullet.rectangle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivitySheet(selectedDate: selectedDate, sessions: templateSessions)
            }
            .sheet(isPresented: $showingSchedulePlan) {
                SchedulePlanSheet(selectedDate: selectedDate, plans: plans)
            }
            .sheet(item: $selectedActivity) { activity in
                ActivityDetailSheet(activity: activity)
            }
        }
    }

    // MARK: - Calendar Header

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                withAnimation {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // MARK: - Upcoming Today

    private var upcomingTodaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text("Coming Up Today")
                    .font(.headline)
            }

            ForEach(upcomingTodayActivities) { activity in
                UpcomingActivityRow(activity: activity) {
                    selectedActivity = activity
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Upcoming This Week

    private var upcomingThisWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.orange)
                Text("Later This Week")
                    .font(.headline)
            }

            ForEach(upcomingThisWeekActivities.prefix(5)) { activity in
                UpcomingActivityRow(activity: activity, showDate: true) {
                    selectedActivity = activity
                }
            }

            if upcomingThisWeekActivities.count > 5 {
                Text("+\(upcomingThisWeekActivities.count - 5) more")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Grid

    private let dayHeaders = [
        (id: 0, label: "S"),
        (id: 1, label: "M"),
        (id: 2, label: "T"),
        (id: 3, label: "W"),
        (id: 4, label: "T"),
        (id: 5, label: "F"),
        (id: 6, label: "S")
    ]

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day of week headers
            HStack {
                ForEach(dayHeaders, id: \.id) { day in
                    Text(day.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            activities: activitiesForDate(date),
                            completedSessions: completedSessionsForDate(date)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // Fill remaining cells
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func activitiesForDate(_ date: Date) -> [ScheduledActivity] {
        activities.filter { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    private func completedSessionsForDate(_ date: Date) -> [SessionLog] {
        sessionLogs.filter {
            guard let completedAt = $0.completedAt else { return false }
            return calendar.isDate(completedAt, inSameDayAs: date)
        }
    }

    // MARK: - Selected Date Section

    private var upcomingForSelectedDate: [ScheduledActivity] {
        let now = Date()
        return activitiesForSelectedDate
            .filter { !$0.isCompleted && (isTodaySelected ? $0.scheduledDate > now : true) }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private var completedForSelectedDate: [ScheduledActivity] {
        activitiesForSelectedDate.filter { $0.isCompleted }
    }

    private var pastForSelectedDate: [ScheduledActivity] {
        guard isTodaySelected else { return [] }
        let now = Date()
        return activitiesForSelectedDate
            .filter { !$0.isCompleted && $0.scheduledDate <= now }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }

    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if isTodaySelected {
                    Text("Today")
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text(selectedDateString)
                        .font(.headline)
                }

                Spacer()

                Button {
                    showingAddActivity = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }

            if activitiesForSelectedDate.isEmpty && sessionsCompletedOnSelectedDate.isEmpty {
                ContentUnavailableView(
                    "No Activities",
                    systemImage: "calendar.badge.plus",
                    description: Text("Tap + to schedule an activity")
                )
                .frame(height: 120)
            } else {
                // Upcoming activities (for today, only future ones)
                if !upcomingForSelectedDate.isEmpty {
                    if isTodaySelected {
                        Text("Coming Up")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }

                    ForEach(upcomingForSelectedDate) { activity in
                        if isTodaySelected {
                            TodayActivityRow(activity: activity) {
                                selectedActivity = activity
                            }
                        } else {
                            ActivityRow(activity: activity) {
                                selectedActivity = activity
                            }
                        }
                    }
                }

                // Past uncompleted (missed) - only for today
                if !pastForSelectedDate.isEmpty {
                    Text("Earlier")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    ForEach(pastForSelectedDate) { activity in
                        ActivityRow(activity: activity) {
                            selectedActivity = activity
                        }
                    }
                }

                // Completed activities
                if !completedForSelectedDate.isEmpty {
                    Text("Completed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    ForEach(completedForSelectedDate) { activity in
                        ActivityRow(activity: activity) {
                            selectedActivity = activity
                        }
                    }
                }

                // Completed sessions (from SessionLog)
                if !sessionsCompletedOnSelectedDate.isEmpty {
                    if completedForSelectedDate.isEmpty {
                        Text("Completed")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }

                    ForEach(sessionsCompletedOnSelectedDate) { log in
                        CompletedSessionRow(log: log)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Schedule Plan Sheet

struct SchedulePlanSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let selectedDate: Date
    let plans: [TrainingPlan]

    @State private var selectedPlan: TrainingPlan?
    @State private var startDate: Date = Date()
    @State private var scheduledTime: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Plan") {
                    Picker("Plan", selection: $selectedPlan) {
                        Text("Select a plan").tag(nil as TrainingPlan?)
                        ForEach(plans) { plan in
                            Text(plan.name).tag(plan as TrainingPlan?)
                        }
                    }
                }

                if let plan = selectedPlan {
                    Section("Plan Details") {
                        LabeledContent("Weeks", value: "\(plan.durationWeeks)")
                        LabeledContent("Target Sessions per Week", value: "\(plan.targetSessionsPerWeek)")
                        LabeledContent("Total Sessions", value: "\(plan.sessions.count)")
                    }

                    Section("Schedule") {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("Default Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    }

                    Section {
                        Text("This will create \(plan.sessions.count) training activities on your calendar, starting \(startDate.formatted(date: .abbreviated, time: .omitted)).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
                    .disabled(selectedPlan == nil)
                }
            }
            .onAppear {
                startDate = selectedDate
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                components.hour = 9  // Default to 9 AM
                components.minute = 0
                scheduledTime = calendar.date(from: components) ?? selectedDate
            }
        }
    }

    private func schedulePlan() {
        guard let plan = selectedPlan else { return }

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
                // weekNumber is 1-based, spread sessions throughout the week
                let weekOffset = weekNumber - 1
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: startDate) else { continue }

                // Space sessions evenly through the week (e.g., Mon, Wed, Fri for 3 sessions)
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
            }
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let activities: [ScheduledActivity]
    let completedSessions: [SessionLog]
    let onTap: () -> Void

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var hasActivity: Bool {
        !activities.isEmpty || !completedSessions.isEmpty
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : isToday ? .blue : .primary)

                // Activity indicators
                if hasActivity {
                    HStack(spacing: 2) {
                        ForEach(Array(activityColors.prefix(3)), id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(width: 40, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var activityColors: [Color] {
        var colors: [Color] = []

        for activity in activities {
            colors.append(colorForType(activity.activityType))
        }

        if !completedSessions.isEmpty {
            colors.append(.blue)
        }

        return colors
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .training: return .blue
        case .gym: return .purple
        case .game: return .green
        case .recovery: return .orange
        case .cardio: return .red
        }
    }
}

// MARK: - Upcoming Activity Row

struct UpcomingActivityRow: View {
    let activity: ScheduledActivity
    var showDate: Bool = false
    let onTap: () -> Void

    private var timeString: String {
        if showDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
            return formatter.string(from: activity.scheduledDate)
        } else {
            return activity.formattedTime
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity type icon
                Image(systemName: activity.activityType.iconName)
                    .font(.title3)
                    .foregroundStyle(colorForType(activity.activityType))
                    .frame(width: 36, height: 36)
                    .background(colorForType(activity.activityType).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(timeString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Time until
                if !showDate {
                    Text(timeUntil)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var timeUntil: String {
        let interval = activity.scheduledDate.timeIntervalSinceNow
        let minutes = Int(interval / 60)

        if minutes < 60 {
            return "in \(minutes)m"
        } else {
            let hours = minutes / 60
            return "in \(hours)h"
        }
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .training: return .blue
        case .gym: return .purple
        case .game: return .green
        case .recovery: return .orange
        case .cardio: return .red
        }
    }
}

// MARK: - Today Activity Row

struct TodayActivityRow: View {
    @Environment(\.modelContext) private var modelContext
    let activity: ScheduledActivity
    let onTap: () -> Void

    private var timeUntil: String {
        let interval = activity.scheduledDate.timeIntervalSinceNow
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "in \(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "in \(hours)h"
            }
            return "in \(hours)h \(remainingMinutes)m"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity type icon
                Image(systemName: activity.activityType.iconName)
                    .font(.title2)
                    .foregroundStyle(colorForType(activity.activityType))
                    .frame(width: 40, height: 40)
                    .background(colorForType(activity.activityType).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.title)
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(activity.formattedTime)
                        Text("•")
                        Text(activity.formattedDuration)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Time until badge
                Text(timeUntil)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.blue.opacity(0.12))
                    .clipShape(Capsule())

                // Completion toggle
                Button {
                    withAnimation {
                        activity.markCompleted()
                    }
                } label: {
                    Image(systemName: "circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .training: return .blue
        case .gym: return .purple
        case .game: return .green
        case .recovery: return .orange
        case .cardio: return .red
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    @Environment(\.modelContext) private var modelContext
    let activity: ScheduledActivity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: activity.activityType.iconName)
                    .font(.title2)
                    .foregroundStyle(colorForType(activity.activityType))
                    .frame(width: 40, height: 40)
                    .background(colorForType(activity.activityType).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(activity.title)
                            .font(.headline)
                            .foregroundStyle(activity.isCompleted ? .secondary : .primary)
                            .strikethrough(activity.isCompleted)

                        if activity.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(activity.formattedTime)
                        Text("•")
                        Text(activity.formattedDuration)
                        Text("•")
                        Text(activity.activityType.rawValue)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Completion toggle
                Button {
                    withAnimation {
                        if activity.isCompleted {
                            activity.markIncomplete()
                        } else {
                            activity.markCompleted()
                        }
                    }
                } label: {
                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(activity.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .training: return .blue
        case .gym: return .purple
        case .game: return .green
        case .recovery: return .orange
        case .cardio: return .red
        }
    }
}

// MARK: - Completed Session Row

struct CompletedSessionRow: View {
    let log: SessionLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(log.sessionName)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .strikethrough()

                HStack(spacing: 8) {
                    if let completedAt = log.completedAt {
                        Text(completedAt.formatted(date: .omitted, time: .shortened))
                    }
                    Text("•")
                    Text("\(log.exercisesCompleted) exercises")
                    Text("•")
                    Text("Completed")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Activity Sheet

struct AddActivitySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let selectedDate: Date
    let sessions: [TrainingSession]

    @State private var title: String = ""
    @State private var activityType: ActivityType = .gym
    @State private var scheduledTime: Date = Date()
    @State private var durationMinutes: Int = 60
    @State private var notes: String = ""
    @State private var selectedSession: TrainingSession?

    // Recurrence options
    @State private var recurrenceType: RecurrenceType = .none
    @State private var recurrenceEndDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showingRecurrenceInfo = false

    private var recurrenceCount: Int {
        guard recurrenceType != .none,
              let component = recurrenceType.calendarComponent else { return 0 }

        let calendar = Calendar.current
        var count = 0
        var currentDate = selectedDate

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
                Section("Activity Type") {
                    Picker("Type", selection: $activityType) {
                        ForEach(ActivityType.allCases) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: activityType) { _, newValue in
                        durationMinutes = newValue.defaultDuration
                        if newValue != .training {
                            selectedSession = nil
                        }
                    }
                }

                if activityType == .training && !sessions.isEmpty {
                    Section("Link to Session") {
                        Picker("Session", selection: $selectedSession) {
                            Text("Custom").tag(nil as TrainingSession?)
                            ForEach(sessions) { session in
                                Text(session.name).tag(session as TrainingSession?)
                            }
                        }
                        .onChange(of: selectedSession) { _, session in
                            if let session {
                                title = session.name
                                durationMinutes = session.totalDurationSeconds / 60
                            }
                        }
                    }
                }

                Section("Details") {
                    TextField("Title", text: $title)

                    DatePicker("Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)

                    Stepper("Duration: \(durationMinutes) min", value: $durationMinutes, in: 15...240, step: 15)
                }

                Section {
                    Picker("Repeat", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if recurrenceType != .none {
                        DatePicker(
                            "Until",
                            selection: $recurrenceEndDate,
                            in: selectedDate...,
                            displayedComponents: .date
                        )

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("Will create \(recurrenceCount) activities")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Recurrence")
                } footer: {
                    if recurrenceType != .none {
                        Text("Activities will be scheduled \(recurrenceType.displayName.lowercased()) from \(selectedDate.formatted(date: .abbreviated, time: .omitted)) until \(recurrenceEndDate.formatted(date: .abbreviated, time: .omitted))")
                    }
                }

                Section("Notes (Optional)") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Activity")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addActivities()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                // Set initial time to selected date
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                let now = Date()
                components.hour = calendar.component(.hour, from: now)
                components.minute = 0
                scheduledTime = calendar.date(from: components) ?? selectedDate
            }
        }
    }

    private func addActivities() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)

        // Generate recurrence group ID if recurring
        let groupId: UUID? = recurrenceType != .none ? UUID() : nil

        // Create activities for each date
        var dates: [Date] = []

        if recurrenceType == .none {
            dates = [selectedDate]
        } else if let component = recurrenceType.calendarComponent {
            var currentDate = selectedDate
            while currentDate <= recurrenceEndDate {
                dates.append(currentDate)
                if let nextDate = calendar.date(byAdding: component, value: recurrenceType.componentValue, to: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }
        }

        for date in dates {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            let fullDate = calendar.date(from: dateComponents) ?? date

            let activity: ScheduledActivity
            if let session = selectedSession {
                activity = ScheduledActivity(session: session, scheduledDate: fullDate)
            } else {
                activity = ScheduledActivity(
                    title: title,
                    type: activityType,
                    scheduledDate: fullDate,
                    durationMinutes: durationMinutes,
                    notes: notes
                )
            }

            // Set recurrence info
            activity.recurrenceType = recurrenceType
            activity.recurrenceGroupId = groupId
            if recurrenceType != .none {
                activity.recurrenceEndDate = recurrenceEndDate
            }

            modelContext.insert(activity)
        }
    }
}

// MARK: - Activity Detail Sheet

struct ActivityDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var activity: ScheduledActivity

    @State private var showingDeleteAlert = false
    @State private var showingDeleteSeriesAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: activity.activityType.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(colorForType(activity.activityType))
                            .frame(width: 60, height: 60)
                            .background(colorForType(activity.activityType).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(activity.title)
                                    .font(.title3)
                                    .fontWeight(.bold)

                                if activity.isRecurring {
                                    Image(systemName: "repeat")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(activity.activityType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Schedule") {
                    LabeledContent("Date", value: activity.formattedDate)
                    LabeledContent("Time", value: activity.formattedTime)
                    LabeledContent("Duration", value: activity.formattedDuration)
                }

                if activity.isRecurring {
                    Section("Recurrence") {
                        LabeledContent("Repeats", value: activity.recurrenceType.displayName)
                        if let endDate = activity.recurrenceEndDate {
                            LabeledContent("Until", value: endDate.formatted(date: .abbreviated, time: .omitted))
                        }
                    }
                }

                if !activity.notes.isEmpty {
                    Section("Notes") {
                        Text(activity.notes)
                    }
                }

                Section {
                    Button {
                        withAnimation {
                            if activity.isCompleted {
                                activity.markIncomplete()
                            } else {
                                activity.markCompleted()
                            }
                        }
                    } label: {
                        Label(
                            activity.isCompleted ? "Mark as Incomplete" : "Mark as Complete",
                            systemImage: activity.isCompleted ? "xmark.circle" : "checkmark.circle"
                        )
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Activity", systemImage: "trash")
                    }

                    if activity.isRecurring && activity.recurrenceGroupId != nil {
                        Button(role: .destructive) {
                            showingDeleteSeriesAlert = true
                        } label: {
                            Label("Delete All in Series", systemImage: "trash.fill")
                        }
                    }
                }
            }
            .navigationTitle("Activity Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Activity?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    modelContext.delete(activity)
                    dismiss()
                }
            }
            .alert("Delete All Activities in Series?", isPresented: $showingDeleteSeriesAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    deleteAllInSeries()
                    dismiss()
                }
            } message: {
                Text("This will delete all future activities in this recurring series. Past completed activities will not be affected.")
            }
        }
    }

    private func deleteAllInSeries() {
        guard let groupId = activity.recurrenceGroupId else { return }

        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate<ScheduledActivity> { $0.recurrenceGroupId == groupId }
        )

        do {
            let activitiesInSeries = try modelContext.fetch(descriptor)
            for seriesActivity in activitiesInSeries {
                // Only delete future uncompleted activities
                if !seriesActivity.isCompleted && seriesActivity.scheduledDate >= Date() {
                    modelContext.delete(seriesActivity)
                }
            }
        } catch {
            print("Failed to delete series: \(error)")
        }
    }

    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .training: return .blue
        case .gym: return .purple
        case .game: return .green
        case .recovery: return .orange
        case .cardio: return .red
        }
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [ScheduledActivity.self, SessionLog.self, TrainingSession.self], inMemory: true)
}
