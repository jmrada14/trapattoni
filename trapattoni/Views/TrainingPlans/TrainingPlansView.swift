import SwiftUI
import SwiftData

struct TrainingPlansView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TrainingPlan.updatedAt, order: .reverse)
    private var plans: [TrainingPlan]

    @State private var showingCreatePlan = false
    @State private var selectedPlan: TrainingPlan?
    @State private var planToDelete: TrainingPlan?
    @State private var showingDeleteAlert = false

    private var activePlan: TrainingPlan? {
        plans.first { $0.isActive }
    }

    private var availablePlans: [TrainingPlan] {
        plans.filter { !$0.isActive && !$0.isFinished }
    }

    private var prebuiltPlans: [TrainingPlan] {
        availablePlans.filter { $0.isPrebuilt }
    }

    private var customPlans: [TrainingPlan] {
        availablePlans.filter { !$0.isPrebuilt }
    }

    private var completedPlans: [TrainingPlan] {
        plans.filter { $0.isFinished }
    }

    var body: some View {
        NavigationStack {
            List {
                // Active Plan Section
                if let active = activePlan {
                    Section {
                        ActivePlanCard(plan: active)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlan = active
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    planToDelete = active
                                    showingDeleteAlert = true
                                } label: {
                                    Label("common.delete".localized, systemImage: "trash")
                                }
                            }
                    } header: {
                        Label("plans.active".localized, systemImage: "play.circle.fill")
                    }
                }

                // Custom Plans Section
                Section {
                    if customPlans.isEmpty && !plans.contains(where: { !$0.isPrebuilt }) {
                        Button {
                            showingCreatePlan = true
                        } label: {
                            Label("plans.createFirst".localized, systemImage: "plus.circle")
                        }
                    } else {
                        ForEach(customPlans) { plan in
                            PlanRowView(plan: plan)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPlan = plan
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        planToDelete = plan
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("common.delete".localized, systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        duplicatePlan(plan)
                                    } label: {
                                        Label("sessions.duplicate".localized, systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }

                        Button {
                            showingCreatePlan = true
                        } label: {
                            Label("plans.new".localized, systemImage: "plus.circle")
                        }
                    }
                } header: {
                    Text("plans.myPlans".localized)
                }

                // Prebuilt Plans Section
                if !prebuiltPlans.isEmpty {
                    Section {
                        ForEach(prebuiltPlans) { plan in
                            PlanRowView(plan: plan)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPlan = plan
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        duplicatePlan(plan)
                                    } label: {
                                        Label("sessions.copy".localized, systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        Text("plans.starterPlans".localized)
                    } footer: {
                        Text("plans.starterPlansFooter".localized)
                    }
                }

                // Completed Plans Section
                if !completedPlans.isEmpty {
                    Section {
                        ForEach(completedPlans) { plan in
                            PlanRowView(plan: plan, showCompleted: true)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedPlan = plan
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        planToDelete = plan
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("common.delete".localized, systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        restartPlan(plan)
                                    } label: {
                                        Label("plans.restart".localized, systemImage: "arrow.counterclockwise")
                                    }
                                    .tint(.green)
                                }
                        }
                    } header: {
                        Text("plans.completed".localized)
                    } footer: {
                        Text("plans.completedFooter".localized)
                    }
                }
            }
            .navigationTitle("plans.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Label("plans.new".localized, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                CreatePlanView()
            }
            .navigationDestination(item: $selectedPlan) { plan in
                PlanDetailView(plan: plan)
            }
            .alert("plans.delete".localized, isPresented: $showingDeleteAlert) {
                Button("common.cancel".localized, role: .cancel) {
                    planToDelete = nil
                }
                Button("common.delete".localized, role: .destructive) {
                    if let plan = planToDelete {
                        deletePlan(plan)
                    }
                }
            } message: {
                Text("plans.deleteConfirm".localized)
            }
            .observeLanguageChanges()
        }
    }

    private func deletePlan(_ plan: TrainingPlan) {
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
                    planToDelete = nil
                }
            }
        } else {
            // No activities to delete, just delete the plan
            modelContext.delete(plan)
            planToDelete = nil
        }
    }

    private func duplicatePlan(_ plan: TrainingPlan) {
        let duplicate = TrainingPlan(
            name: "\(plan.localizedName) (Copy)",
            description: plan.planDescription,
            durationWeeks: plan.durationWeeks,
            targetSessionsPerWeek: plan.targetSessionsPerWeek
        )
        duplicate.isPrebuilt = false

        // Duplicate sessions
        for session in plan.sessions {
            let duplicateSession = PlanSession(
                sessionId: session.sessionId,
                sessionName: session.sessionName,
                week: session.weekNumber,
                dayOfWeek: 0,
                orderIndex: session.orderInWeek
            )
            duplicate.sessions.append(duplicateSession)
        }

        modelContext.insert(duplicate)
    }

    private func restartPlan(_ plan: TrainingPlan) {
        plan.restart()
    }
}

// MARK: - Plan Row View

struct PlanRowView: View {
    let plan: TrainingPlan
    var showCompleted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: plan.isPrebuilt ? "star.circle.fill" : "calendar.circle.fill")
                .font(.title2)
                .foregroundStyle(plan.isPrebuilt ? .yellow : .blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.localizedName)
                    .font(.headline)

                HStack(spacing: 8) {
                    Label("\(plan.durationWeeks) weeks", systemImage: "calendar")
                    Label("\(plan.targetSessionsPerWeek)x/week", systemImage: "repeat")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if showCompleted, let completedAt = plan.completedAt {
                    Text("Completed \(completedAt, style: .date)")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TrainingPlansView()
        .modelContainer(for: [TrainingPlan.self, TrainingSession.self], inMemory: true)
}
