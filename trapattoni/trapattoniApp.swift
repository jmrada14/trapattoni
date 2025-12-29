//
//  trapattoniApp.swift
//  trapattoni
//
//  Created by Juan Manuel Rada Leon on 12/27/25.
//

import SwiftUI
import SwiftData

@main
struct trapattoniApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            // Exercise Library
            Exercise.self,
            // Training Sessions
            TrainingSession.self,
            SessionExercise.self,
            // Progress Tracking
            SessionLog.self,
            ExerciseRating.self,
            // Training Plans
            TrainingPlan.self,
            PlanSession.self,
            // Tactical Board
            TacticSheet.self,
            BoardElement.self,
            DrawingPath.self,
            // Player Profile
            PlayerProfile.self,
            // Scheduled Activities
            ScheduledActivity.self
        ])
        // Local storage configuration
        // To enable iCloud sync, change to:
        // cloudKitDatabase: .private("iCloud.com.ks.trapattoni")
        // (Requires paid Apple Developer Program membership)
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await seedDataIfNeeded()
                    await requestNotificationPermission()
                    await requestCalendarPermission()
                    await updateSmartReminders()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await syncDeletedCalendarEvents()
                }
            }
        }
    }

    @MainActor
    private func requestNotificationPermission() async {
        let granted = await NotificationService.shared.requestPermission()
        if granted {
            print("Notification permission granted")
        }
    }

    @MainActor
    private func requestCalendarPermission() async {
        let granted = await CalendarService.shared.requestPermission()
        if granted {
            print("Calendar permission granted")
        }
    }

    @MainActor
    private func syncDeletedCalendarEvents() async {
        let context = sharedModelContainer.mainContext

        // Refresh event store to get latest changes
        CalendarService.shared.refreshEventStore()

        // Fetch all activities with calendar event IDs
        let descriptor = FetchDescriptor<ScheduledActivity>(
            predicate: #Predicate<ScheduledActivity> { $0.calendarEventId != nil }
        )

        guard let activities = try? context.fetch(descriptor) else { return }

        // Check each activity's calendar event
        for activity in activities {
            if let eventId = activity.calendarEventId {
                // If event no longer exists in calendar, clear the ID
                if !CalendarService.shared.eventExists(eventIdentifier: eventId) {
                    activity.calendarEventId = nil
                    print("Calendar event externally deleted for: \(activity.title)")
                }
            }
        }
    }

    @MainActor
    private func updateSmartReminders() async {
        let context = sharedModelContainer.mainContext

        // Fetch profile
        let profileDescriptor = FetchDescriptor<PlayerProfile>()
        guard let profile = try? context.fetch(profileDescriptor).first else { return }

        // Fetch last completed training session
        var logDescriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate<SessionLog> { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        logDescriptor.fetchLimit = 1
        let lastTrainingDate = try? context.fetch(logDescriptor).first?.completedAt

        // Calculate sessions completed this week
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now

        let weekLogDescriptor = FetchDescriptor<SessionLog>(
            predicate: #Predicate<SessionLog> { log in
                log.completedAt != nil && log.completedAt! >= startOfWeek
            }
        )
        let sessionsThisWeek = (try? context.fetch(weekLogDescriptor).count) ?? 0

        // Update smart reminders
        await NotificationService.shared.updateSmartReminders(
            profile: profile,
            lastTrainingDate: lastTrainingDate,
            sessionsThisWeek: sessionsThisWeek
        )
    }

    @MainActor
    private func seedDataIfNeeded() async {
        let context = sharedModelContainer.mainContext

        // Seed exercises first
        do {
            try await ExerciseDataSeeder.seedIfNeeded(modelContext: context)
        } catch {
            print("Failed to seed exercise data: \(error.localizedDescription)")
        }

        // Seed starter sessions and prebuilt plans
        do {
            try await PlanDataSeeder.seedIfNeeded(modelContext: context)
        } catch {
            print("Failed to seed plan data: \(error.localizedDescription)")
        }
    }
}
