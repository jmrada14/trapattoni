import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PlayerProfile]
    @Query(sort: \SessionLog.completedAt, order: .reverse)
    private var sessionLogs: [SessionLog]

    @State private var stats: StatsService.OverviewStats?
    @State private var categoryProgress: [StatsService.CategoryProgress] = []
    @State private var selectedLog: SessionLog?
    @State private var isLoading = true
    @State private var showingEditProfile = false
    @State private var showingResetAlert = false
    @State private var logToDelete: SessionLog?
    @State private var showingDeleteLogAlert = false
    @State private var showingExerciseHistory = false

    private var profile: PlayerProfile? {
        profiles.first
    }

    private var completedLogs: [SessionLog] {
        sessionLogs.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(
                        profile: profile,
                        stats: stats,
                        onEdit: { showingEditProfile = true }
                    )

                    if isLoading {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else if let stats {
                        // Quick Stats Row
                        QuickStatsRow(stats: stats)

                        // Activity Stats Row
                        if stats.totalGymSessions > 0 || stats.totalGames > 0 || stats.totalCardio > 0 || stats.totalRecovery > 0 {
                            ActivityStatsRow(stats: stats)
                        }

                        // Streak Calendar
                        StreakCalendarView(trainingDays: getTrainingDays())

                        // Category Progress
                        if !categoryProgress.isEmpty {
                            CategoryProgressView(progress: categoryProgress)
                        }

                        // Exercise History Button
                        NavigationLink {
                            ExerciseHistoryView()
                        } label: {
                            HStack {
                                Label("profile.exerciseHistory".localized, systemImage: "list.bullet.rectangle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        // Recent Sessions
                        if !completedLogs.isEmpty {
                            SessionHistorySection(
                                logs: Array(completedLogs.prefix(5)),
                                onSelect: { selectedLog = $0 },
                                onDelete: { log in
                                    logToDelete = log
                                    showingDeleteLogAlert = true
                                }
                            )
                        }
                    } else {
                        // Empty state
                        ContentUnavailableView(
                            "profile.startTraining".localized,
                            systemImage: "figure.run",
                            description: Text("profile.completeFirstSession".localized)
                        )
                        .padding(.vertical, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("profile.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Label("profile.editProfile".localized, systemImage: "pencil")
                        }

                        if !completedLogs.isEmpty {
                            Divider()

                            Button(role: .destructive) {
                                showingResetAlert = true
                            } label: {
                                Label("profile.resetProgress".localized, systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .observeLanguageChanges()
            .onAppear {
                ensureProfileExists()
                loadStats()
            }
            .refreshable {
                loadStats()
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile {
                    EditProfileView(profile: profile)
                }
            }
            .navigationDestination(item: $selectedLog) { log in
                SessionLogDetailView(log: log)
            }
            .alert("progress.resetConfirm".localized, isPresented: $showingResetAlert) {
                Button("common.cancel".localized, role: .cancel) {}
                Button("stats.reset".localized, role: .destructive) {
                    resetAllProgress()
                }
            } message: {
                Text("progress.resetMessage".localized)
            }
            .alert("progress.deleteLogConfirm".localized, isPresented: $showingDeleteLogAlert) {
                Button("common.cancel".localized, role: .cancel) {
                    logToDelete = nil
                }
                Button("common.delete".localized, role: .destructive) {
                    if let log = logToDelete {
                        deleteLog(log)
                    }
                }
            } message: {
                Text("progress.deleteLogMessage".localized)
            }
        }
    }

    private func ensureProfileExists() {
        guard profiles.isEmpty else { return }
        let newProfile = PlayerProfile()
        modelContext.insert(newProfile)
    }

    private func loadStats() {
        isLoading = true
        let service = StatsService(modelContext: modelContext)

        do {
            stats = try service.calculateOverviewStats()
            categoryProgress = try service.calculateCategoryProgress()
        } catch {
            print("Failed to load stats: \(error)")
        }

        isLoading = false
    }

    private func getTrainingDays() -> Set<DateComponents> {
        let calendar = Calendar.current
        return Set(completedLogs.compactMap { log -> DateComponents? in
            guard let date = log.completedAt else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: date)
        })
    }

    private func deleteLog(_ log: SessionLog) {
        modelContext.delete(log)
        logToDelete = nil
        loadStats()
    }

    private func resetAllProgress() {
        for log in sessionLogs {
            modelContext.delete(log)
        }
        loadStats()
    }
}

// MARK: - Profile Header View

struct ProfileHeaderView: View {
    let profile: PlayerProfile?
    let stats: StatsService.OverviewStats?
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                if let photoData = profile?.photoData,
                   let image = platformImage(from: photoData) {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    #endif
                } else {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white)
                        }
                }

                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .blue)
                        .background(Circle().fill(.white).padding(4))
                }
                .offset(x: 35, y: 35)
            }

            // Name and Bio
            VStack(spacing: 4) {
                Text(profile?.name.isEmpty == false ? profile!.name : "Player")
                    .font(.title2)
                    .fontWeight(.bold)

                if let position = profile?.position, !position.isEmpty,
                   let playerPosition = PlayerPosition(rawValue: position) {
                    Text(playerPosition.localizedName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let bio = profile?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                }
            }

            // Player info badges
            if let profile, hasPlayerInfo(profile) {
                HStack(spacing: 12) {
                    if !profile.preferredFoot.isEmpty,
                       let foot = PreferredFoot(rawValue: profile.preferredFoot.capitalized) {
                        InfoBadge(
                            icon: "shoe.fill",
                            text: foot.localizedName
                        )
                    }

                    if profile.yearsPlaying > 0 {
                        InfoBadge(
                            icon: "calendar",
                            text: "\(profile.yearsPlaying) \("profile.yearsPlaying".localized.lowercased())"
                        )
                    }

                    if let streak = stats?.currentStreak, streak > 0 {
                        InfoBadge(
                            icon: "flame.fill",
                            text: "\(streak) \("stats.streak".localized)",
                            color: .orange
                        )
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func hasPlayerInfo(_ profile: PlayerProfile) -> Bool {
        !profile.preferredFoot.isEmpty || profile.yearsPlaying > 0
    }

    #if os(iOS)
    private func platformImage(from data: Data) -> UIImage? {
        UIImage(data: data)
    }
    #else
    private func platformImage(from data: Data) -> NSImage? {
        NSImage(data: data)
    }
    #endif
}

// MARK: - Info Badge

struct InfoBadge: View {
    let icon: String
    let text: String
    var color: Color = .blue

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Quick Stats Row

struct QuickStatsRow: View {
    let stats: StatsService.OverviewStats

    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "profile.sessions".localized,
                value: "\(stats.totalSessions)",
                icon: "figure.run",
                color: .blue
            )

            StatCard(
                title: "profile.time".localized,
                value: formatTime(stats.totalTimeMinutes),
                icon: "clock",
                color: .green
            )

            StatCard(
                title: "profile.exercises".localized,
                value: "\(stats.totalExercises)",
                icon: "dumbbell",
                color: .orange
            )
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var profile: PlayerProfile

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var position: String = ""
    @State private var preferredFoot: String = "right"
    @State private var yearsPlaying: Int = 0
    @State private var weeklyGoal: Int = 3
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    // Notification settings
    @State private var notificationsEnabled: Bool = true
    @State private var inactivityRemindersEnabled: Bool = true
    @State private var inactivityDaysThreshold: Int = 3
    @State private var weeklyGoalRemindersEnabled: Bool = true
    @State private var reminderTime: Date = Date()

    // Language settings
    @State private var selectedLanguage: AppLanguage = .english

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                if let photoData,
                                   let image = platformImage(from: photoData) {
                                    #if os(iOS)
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    #else
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    #endif
                                } else {
                                    Circle()
                                        .fill(Color.blue.gradient)
                                        .frame(width: 100, height: 100)
                                        .overlay {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(.white)
                                        }
                                }

                                Circle()
                                    .stroke(.blue, lineWidth: 3)
                                    .frame(width: 100, height: 100)
                            }
                        }

                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // Basic Info
                Section("profile.basicInfo".localized) {
                    TextField("profile.name".localized, text: $name)

                    TextField("profile.bio".localized, text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Player Details
                Section("profile.playerDetails".localized) {
                    Picker("profile.position".localized, selection: $position) {
                        Text("profile.notSet".localized).tag("")
                        ForEach(PlayerPosition.allCases) { pos in
                            Text(pos.localizedName).tag(pos.rawValue)
                        }
                    }

                    Picker("profile.preferredFoot".localized, selection: $preferredFoot) {
                        ForEach(PreferredFoot.allCases) { foot in
                            Text(foot.localizedName).tag(foot.rawValue.lowercased())
                        }
                    }

                    Stepper("\("profile.yearsPlaying".localized): \(yearsPlaying)", value: $yearsPlaying, in: 0...50)
                }

                // Training Goals
                Section("profile.trainingGoals".localized) {
                    Stepper("\("profile.weeklyGoal".localized): \(weeklyGoal) \("profile.sessionsPerWeek".localized)", value: $weeklyGoal, in: 1...7)
                }

                // Language Settings
                Section {
                    Picker("profile.language".localized, selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                } header: {
                    Label("profile.language".localized, systemImage: "globe")
                } footer: {
                    Text("profile.languageFooter".localized)
                }

                // Notification Settings
                Section {
                    Toggle("profile.enableNotifications".localized, isOn: $notificationsEnabled)
                } header: {
                    Label("profile.notifications".localized, systemImage: "bell.fill")
                }

                if notificationsEnabled {
                    Section {
                        Toggle("profile.inactivityReminders".localized, isOn: $inactivityRemindersEnabled)

                        if inactivityRemindersEnabled {
                            Stepper("profile.remindAfterDays".localized(with: inactivityDaysThreshold), value: $inactivityDaysThreshold, in: 1...7)
                        }
                    } header: {
                        Text("profile.stayActive".localized)
                    } footer: {
                        Text("profile.stayActiveFooter".localized)
                    }

                    Section {
                        Toggle("profile.weeklyGoalReminders".localized, isOn: $weeklyGoalRemindersEnabled)
                    } header: {
                        Text("profile.goalProgress".localized)
                    } footer: {
                        Text("profile.goalProgressFooter".localized)
                    }

                    Section {
                        DatePicker("profile.reminderTime".localized, selection: $reminderTime, displayedComponents: .hourAndMinute)
                    } footer: {
                        Text("profile.reminderTimeFooter".localized)
                    }
                }
            }
            .navigationTitle("profile.editProfile".localized)
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
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .observeLanguageChanges()
            .onAppear {
                loadProfileData()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private func loadProfileData() {
        name = profile.name
        bio = profile.bio
        position = profile.position
        preferredFoot = profile.preferredFoot
        yearsPlaying = profile.yearsPlaying
        weeklyGoal = profile.weeklyGoalSessions
        photoData = profile.photoData

        // Notification settings
        notificationsEnabled = profile.notificationsEnabled
        inactivityRemindersEnabled = profile.inactivityRemindersEnabled
        inactivityDaysThreshold = profile.inactivityDaysThreshold
        weeklyGoalRemindersEnabled = profile.weeklyGoalRemindersEnabled
        reminderTime = profile.reminderTime

        // Language
        selectedLanguage = profile.language
    }

    private func saveProfile() {
        profile.name = name
        profile.bio = bio
        profile.position = position
        profile.preferredFoot = preferredFoot
        profile.yearsPlaying = yearsPlaying
        profile.weeklyGoalSessions = weeklyGoal
        profile.photoData = photoData
        profile.updatedAt = Date()

        // Notification settings
        profile.notificationsEnabled = notificationsEnabled
        profile.inactivityRemindersEnabled = inactivityRemindersEnabled
        profile.inactivityDaysThreshold = inactivityDaysThreshold
        profile.weeklyGoalRemindersEnabled = weeklyGoalRemindersEnabled
        profile.reminderTime = reminderTime

        // Language
        profile.language = selectedLanguage
        LocalizationManager.shared.setLanguage(selectedLanguage)

        // Update smart reminders with new settings
        Task {
            await updateSmartRemindersAfterSave()
        }
    }

    private func updateSmartRemindersAfterSave() async {
        // Fetch last completed training session
        var logDescriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate<SessionLog> { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        logDescriptor.fetchLimit = 1
        let lastTrainingDate = try? modelContext.fetch(logDescriptor).first?.completedAt

        // Calculate sessions completed this week
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        let weekLogDescriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate<SessionLog> { log in
                log.completedAt != nil && log.completedAt! >= startOfWeek
            }
        )
        let sessionsThisWeek = (try? modelContext.fetch(weekLogDescriptor).count) ?? 0

        await NotificationService.shared.updateSmartReminders(
            profile: profile,
            lastTrainingDate: lastTrainingDate,
            sessionsThisWeek: sessionsThisWeek
        )
    }

    #if os(iOS)
    private func platformImage(from data: Data) -> UIImage? {
        UIImage(data: data)
    }
    #else
    private func platformImage(from data: Data) -> NSImage? {
        NSImage(data: data)
    }
    #endif
}

// MARK: - Activity Stats Row

struct ActivityStatsRow: View {
    let stats: StatsService.OverviewStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("profile.activityBreakdown".localized)
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if stats.totalGymSessions > 0 {
                    ActivityStatCard(
                        title: "profile.gym".localized,
                        count: stats.totalGymSessions,
                        icon: "dumbbell.fill",
                        color: .purple
                    )
                }

                if stats.totalGames > 0 {
                    ActivityStatCard(
                        title: "profile.games".localized,
                        count: stats.totalGames,
                        icon: "sportscourt.fill",
                        color: .green
                    )
                }

                if stats.totalCardio > 0 {
                    ActivityStatCard(
                        title: "profile.cardio".localized,
                        count: stats.totalCardio,
                        icon: "figure.run.circle.fill",
                        color: .red
                    )
                }

                if stats.totalRecovery > 0 {
                    ActivityStatCard(
                        title: "profile.recovery".localized,
                        count: stats.totalRecovery,
                        icon: "heart.circle.fill",
                        color: .orange
                    )
                }
            }

            if stats.thisWeekActivities > 0 {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundStyle(.blue)
                    Text("\(stats.thisWeekActivities) \("profile.activitiesThisWeek".localized)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Activity Stat Card

struct ActivityStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [
            PlayerProfile.self,
            SessionLog.self,
            ExerciseRating.self,
            ScheduledActivity.self
        ], inMemory: true)
}
