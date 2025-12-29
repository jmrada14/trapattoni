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
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func requestNotificationPermission() async {
        let granted = await NotificationService.shared.requestPermission()
        if granted {
            print("Notification permission granted")
        }
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
