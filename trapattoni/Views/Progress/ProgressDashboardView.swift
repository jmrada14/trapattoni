import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SessionLog.completedAt, order: .reverse)
    private var sessionLogs: [SessionLog]

    @State private var stats: StatsService.OverviewStats?
    @State private var categoryProgress: [StatsService.CategoryProgress] = []
    @State private var selectedLog: SessionLog?
    @State private var isLoading = true
    @State private var showingResetAlert = false
    @State private var logToDelete: SessionLog?
    @State private var showingDeleteLogAlert = false

    private var completedLogs: [SessionLog] {
        sessionLogs.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else if let stats {
                        // Overview Stats Card
                        StatsOverviewCard(stats: stats)

                        // Streak Calendar
                        StreakCalendarView(
                            trainingDays: getTrainingDays()
                        )

                        // Category Progress
                        if !categoryProgress.isEmpty {
                            CategoryProgressView(progress: categoryProgress)
                        }

                        // Recent Sessions
                        if !completedLogs.isEmpty {
                            SessionHistorySection(
                                logs: Array(completedLogs.prefix(10)),
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
                            "progress.noDataYet".localized,
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("progress.completeFirst".localized)
                        )
                        .padding(.vertical, 60)
                    }
                }
                .padding()
            }
            .navigationTitle("progress.title".localized)
            .toolbar {
                if !completedLogs.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                showingResetAlert = true
                            } label: {
                                Label("progress.resetAll".localized, systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .observeLanguageChanges()
            .onAppear {
                loadStats()
            }
            .refreshable {
                loadStats()
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

// MARK: - Session History Section

struct SessionHistorySection: View {
    let logs: [SessionLog]
    let onSelect: (SessionLog) -> Void
    var onDelete: ((SessionLog) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("progress.recentSessions".localized)
                    .font(.headline)
                Spacer()
                Text("\(logs.count) \("progress.sessionsCount".localized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                ForEach(logs) { log in
                    SessionLogRow(log: log)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(log)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                onDelete?(log)
                            } label: {
                                Label("common.delete".localized, systemImage: "trash")
                            }
                        }

                    if log.id != logs.last?.id {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Session Log Row

struct SessionLogRow: View {
    let log: SessionLog

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Circle()
                .fill(log.completionPercentage >= 1.0 ? Color.green : Color.orange)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.sessionName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(log.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(log.actualDurationFormatted)
                    .font(.caption)

                if let rating = log.averageRating {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                    }
                }
            }
            .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: [SessionLog.self, ExerciseRating.self], inMemory: true)
}
