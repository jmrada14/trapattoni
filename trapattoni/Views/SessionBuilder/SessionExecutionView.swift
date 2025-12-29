import SwiftUI
import SwiftData

struct SessionExecutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allExercises: [Exercise]

    let session: TrainingSession
    var planId: UUID? = nil

    @State private var timerService = SessionTimerService()
    @State private var sessionLog: SessionLog?
    @State private var exerciseToRate: SessionExercise?
    @State private var pendingRatings: [UUID: Int] = [:]
    @State private var showingQuitConfirmation = false
    @State private var isSkipping = false
    @State private var lastCountdownWarning: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.systemGray5)

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * timerService.progress)
                    }
                }
                .frame(height: 4)

                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // State indicator
                    stateIndicator

                    // Timer display
                    timerDisplay

                    // Current exercise info
                    if let exercise = timerService.currentExercise {
                        exerciseInfo(for: exercise)
                    }

                    // Controls
                    controlButtons
                }
                .padding()

                Spacer()

                // Bottom info
                bottomInfo
            }
            .navigationTitle(session.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") {
                        showingQuitConfirmation = true
                    }
                }
            }
            .onAppear {
                startSession()
            }
            .onChange(of: timerService.state) { oldValue, newValue in
                handleStateChange(from: oldValue, to: newValue)
            }
            .onChange(of: timerService.remainingSeconds) { _, newValue in
                // Play countdown warning ticks in the last 3 seconds
                if newValue <= 3 && newValue > 0 && newValue != lastCountdownWarning {
                    lastCountdownWarning = newValue
                    Task { @MainActor in
                        TimerAlertService.shared.playCountdownWarning()
                    }
                } else if newValue > 3 {
                    lastCountdownWarning = 0
                }
            }
            .confirmationDialog("End Session?", isPresented: $showingQuitConfirmation) {
                Button("End Session", role: .destructive) {
                    endSession(completed: false)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your progress will be saved.")
            }
            .sheet(item: $exerciseToRate) { exercise in
                ExerciseRatingSheet(exercise: exercise) { rating in
                    pendingRatings[exercise.exerciseId] = rating
                    exerciseToRate = nil

                    // If we were skipping, now actually skip to next
                    if isSkipping {
                        isSkipping = false
                        timerService.skip()
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var stateIndicator: some View {
        Group {
            switch timerService.state {
            case .exerciseActive:
                Text("EXERCISE")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.15))
                    .clipShape(Capsule())

            case .restPeriod:
                Text("REST")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.15))
                    .clipShape(Capsule())

            case .paused:
                Text("PAUSED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15))
                    .clipShape(Capsule())

            case .completed:
                Text("COMPLETED")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.15))
                    .clipShape(Capsule())

            case .idle:
                EmptyView()
            }
        }
    }

    private var timerDisplay: some View {
        Text(timerService.formattedTime)
            .font(.system(size: 72, weight: .thin, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(timerService.state == .restPeriod ? .green : .primary)
    }

    private func exerciseInfo(for exercise: SessionExercise) -> some View {
        let fullExercise = allExercises.first(where: { $0.id == exercise.exerciseId })

        return VStack(spacing: 12) {
            // Tactical board visualization
            if timerService.state == .exerciseActive || timerService.state == .paused,
               let fullExercise {
                TacticalBoardView(exercise: fullExercise, isCompact: true)
                    .frame(height: 140)
                    .padding(.horizontal)
            }

            CategoryIconView(category: exercise.exerciseCategory, size: .large)

            Text(exercise.exerciseName)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Exercise description
            if timerService.state == .exerciseActive || timerService.state == .paused,
               let description = fullExercise?.exerciseDescription, !description.isEmpty {
                ScrollView {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 80)
            }

            if timerService.state == .restPeriod, let next = timerService.nextExercise {
                Text("Next: \(next.exerciseName)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 20) {
            // Main controls row
            HStack(spacing: 24) {
                // Skip button
                Button {
                    // Rate current exercise before skipping (if in exercise phase)
                    if timerService.state == .exerciseActive,
                       let exercise = timerService.currentExercise {
                        isSkipping = true
                        exerciseToRate = exercise
                    } else {
                        timerService.skip()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Color.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed)

                // Play/Pause button
                Button {
                    if timerService.state == .paused {
                        timerService.resume()
                    } else {
                        timerService.pause()
                    }
                } label: {
                    Image(systemName: timerService.state == .paused ? "play.fill" : "pause.fill")
                        .font(.title)
                        .frame(width: 72, height: 72)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed)

                // Skip to next (for rest periods)
                Button {
                    timerService.skip()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Color.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed || timerService.state != .restPeriod)
                .opacity(timerService.state == .restPeriod ? 1 : 0.3)
            }

            // Time adjustment row
            HStack(spacing: 16) {
                // Reduce time button
                Button {
                    timerService.reduceTime(by: 30)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "minus")
                            .font(.headline)
                        Text("30s")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(width: 80, height: 40)
                    .background(Color.secondaryBackground)
                    .clipShape(Capsule())
                }
                .disabled(timerService.state == .completed || timerService.state == .restPeriod || timerService.remainingSeconds <= 30)

                // Extend time button
                Button {
                    timerService.extendTime(by: 30)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.headline)
                        Text("30s")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(width: 80, height: 40)
                    .background(Color.secondaryBackground)
                    .clipShape(Capsule())
                }
                .disabled(timerService.state == .completed || timerService.state == .restPeriod)
            }
            .foregroundStyle(.primary)
        }
    }

    private var bottomInfo: some View {
        HStack {
            Label("\(timerService.currentExerciseIndex + 1)/\(session.exercises.count)", systemImage: "list.bullet")

            Spacer()

            Label(timerService.formattedElapsedTime, systemImage: "clock")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding()
        .background(.bar)
    }

    // MARK: - Methods

    private func startSession() {
        let log = SessionLog(session: session, planId: planId)
        modelContext.insert(log)
        sessionLog = log

        // Set up phase completion alerts
        timerService.onPhaseComplete = { completedPhase in
            Task { @MainActor in
                switch completedPhase {
                case .exerciseActive:
                    TimerAlertService.shared.playExerciseCompleteAlert()
                case .restPeriod:
                    TimerAlertService.shared.playRestCompleteAlert()
                default:
                    break
                }
            }
        }

        timerService.start(with: session.sortedExercises)
    }

    private func handleStateChange(from oldValue: SessionTimerService.TimerState, to newValue: SessionTimerService.TimerState) {
        // Prompt for rating when exercise ends
        if oldValue == .exerciseActive && newValue == .restPeriod {
            if let exercise = timerService.currentExercise {
                exerciseToRate = exercise
            }
        }

        // Session completed
        if newValue == .completed {
            // Play completion alert
            Task { @MainActor in
                TimerAlertService.shared.playSessionCompleteAlert()
            }

            // Rate the last exercise
            if let exercise = session.sortedExercises.last,
               pendingRatings[exercise.exerciseId] == nil {
                exerciseToRate = exercise
            } else {
                endSession(completed: true)
            }
        }
    }

    private func endSession(completed: Bool) {
        guard let log = sessionLog else {
            dismiss()
            return
        }

        log.complete(
            exercisesCompleted: completed ? session.exercises.count : timerService.currentExerciseIndex,
            actualDuration: timerService.totalElapsedSeconds
        )

        // Save ratings
        for (exerciseId, rating) in pendingRatings {
            if let exercise = session.exercises.first(where: { $0.exerciseId == exerciseId }) {
                let ratingModel = ExerciseRating(
                    exerciseId: exercise.exerciseId,
                    exerciseName: exercise.exerciseName,
                    exerciseCategory: exercise.exerciseCategory,
                    rating: rating
                )
                log.addRating(ratingModel)
                modelContext.insert(ratingModel)
            }
        }

        timerService.stop()
        dismiss()
    }
}

// MARK: - Exercise Rating Sheet

struct ExerciseRatingSheet: View {
    let exercise: SessionExercise
    let onRate: (Int) -> Void

    @State private var selectedRating: Int = 3

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Rate Exercise")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)

            // Exercise info
            HStack(spacing: 12) {
                CategoryIconView(category: exercise.exerciseCategory, size: .medium)

                VStack(alignment: .leading, spacing: 2) {
                    Text("How did you do?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(exercise.exerciseName)
                        .font(.headline)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Star rating - larger touch targets
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedRating = star
                        }
                    } label: {
                        Image(systemName: star <= selectedRating ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundStyle(star <= selectedRating ? .yellow : .secondary.opacity(0.4))
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)

            // Rating description
            Text(ratingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(height: 20)

            // Continue button
            Button {
                onRate(selectedRating)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding(20)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
    }

    private var ratingDescription: String {
        switch selectedRating {
        case 1: return "Struggled - need more practice"
        case 2: return "Difficult - some improvement needed"
        case 3: return "Okay - decent performance"
        case 4: return "Good - performed well"
        case 5: return "Excellent - nailed it!"
        default: return ""
        }
    }
}

#Preview {
    SessionExecutionView(session: TrainingSession(
        name: "Morning Warmup",
        templateType: .warmUp
    ))
    .modelContainer(for: [TrainingSession.self, SessionLog.self], inMemory: true)
}
