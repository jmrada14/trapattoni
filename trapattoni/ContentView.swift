//
//  ContentView.swift
//  trapattoni
//
//  Created by Juan Manuel Rada Leon on 12/27/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        #if os(iOS)
        TabView {
            ExerciseLibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            TrainingView()
                .tabItem {
                    Label("Training", systemImage: "figure.run")
                }

            TacticsLibraryView()
                .tabItem {
                    Label("Tactics", systemImage: "sportscourt")
                }

            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
        }
        #else
        NavigationSplitView {
            List {
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Label("Exercise Library", systemImage: "books.vertical")
                }

                Section("Training") {
                    NavigationLink {
                        SessionBuilderView()
                    } label: {
                        Label("Sessions", systemImage: "figure.run")
                    }

                    NavigationLink {
                        TrainingPlansView()
                    } label: {
                        Label("Plans", systemImage: "list.bullet.rectangle")
                    }
                }

                NavigationLink {
                    TacticsLibraryView()
                } label: {
                    Label("Tactical Board", systemImage: "sportscourt")
                }

                NavigationLink {
                    CalendarView()
                } label: {
                    Label("Calendar", systemImage: "calendar")
                }

                NavigationLink {
                    ProfileView()
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
            .navigationTitle("Trapattoni")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            ExerciseLibraryView()
        }
        #endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Exercise.self,
            TrainingSession.self,
            SessionLog.self,
            TrainingPlan.self,
            TacticSheet.self,
            PlayerProfile.self,
            ScheduledActivity.self
        ], inMemory: true)
}
