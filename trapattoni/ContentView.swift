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
                    Label("tab.exercises".localized, systemImage: "books.vertical")
                }

            TrainingView()
                .tabItem {
                    Label("tab.sessions".localized, systemImage: "figure.run")
                }

            TacticsLibraryView()
                .tabItem {
                    Label("tab.tactics".localized, systemImage: "sportscourt")
                }

            CalendarView()
                .tabItem {
                    Label("tab.calendar".localized, systemImage: "calendar")
                }

            ProfileView()
                .tabItem {
                    Label("tab.profile".localized, systemImage: "person.crop.circle")
                }
        }
        .observeLanguageChanges()
        #else
        NavigationSplitView {
            List {
                NavigationLink {
                    ExerciseLibraryView()
                } label: {
                    Label("tab.exercises".localized, systemImage: "books.vertical")
                }

                Section("tab.sessions".localized) {
                    NavigationLink {
                        SessionBuilderView()
                    } label: {
                        Label("tab.sessions".localized, systemImage: "figure.run")
                    }

                    NavigationLink {
                        TrainingPlansView()
                    } label: {
                        Label("training.plans".localized, systemImage: "list.bullet.rectangle")
                    }
                }

                NavigationLink {
                    TacticsLibraryView()
                } label: {
                    Label("tab.tactics".localized, systemImage: "sportscourt")
                }

                NavigationLink {
                    CalendarView()
                } label: {
                    Label("tab.calendar".localized, systemImage: "calendar")
                }

                NavigationLink {
                    ProfileView()
                } label: {
                    Label("tab.profile".localized, systemImage: "person.crop.circle")
                }
            }
            .navigationTitle("Trapattoni")
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            ExerciseLibraryView()
        }
        .observeLanguageChanges()
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
