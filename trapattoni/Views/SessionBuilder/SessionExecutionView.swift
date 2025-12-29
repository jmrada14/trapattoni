import SwiftUI
import SwiftData
import UserNotifications

struct SessionExecutionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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
    @State private var voiceEnabled: Bool = true
    @State private var backgroundedAt: Date?

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if isLandscape {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout
                }
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        voiceEnabled.toggle()
                        VoiceAnnouncementService.shared.setEnabled(voiceEnabled)
                    } label: {
                        Image(systemName: voiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                }
            }
            .onAppear {
                startSession()
                TimerAlertService.shared.keepScreenAwake(true)
            }
            .onDisappear {
                TimerAlertService.shared.keepScreenAwake(false)
                VoiceAnnouncementService.shared.stop()
            }
            .onChange(of: timerService.state) { oldValue, newValue in
                handleStateChange(from: oldValue, to: newValue)
            }
            .onChange(of: timerService.remainingSeconds) { _, newValue in
                handleCountdown(newValue)
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
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

                    if isSkipping {
                        isSkipping = false
                        timerService.skip()
                    }
                }
            }
        }
    }

    // MARK: - Portrait Layout

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            progressBar

            Spacer()

            VStack(spacing: 32) {
                stateIndicator
                timerDisplay

                if let exercise = timerService.currentExercise {
                    exerciseInfo(for: exercise, compact: false)
                }

                controlButtons
            }
            .padding()

            Spacer()

            bottomInfo
        }
    }

    // MARK: - Landscape Layout

    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            progressBar

            HStack(spacing: 20) {
                // Left side: Timer and controls
                VStack(spacing: 16) {
                    stateIndicator
                    timerDisplayCompact
                    controlButtonsCompact
                }
                .frame(width: geometry.size.width * 0.4)

                // Right side: Exercise info
                if let exercise = timerService.currentExercise {
                    exerciseInfo(for: exercise, compact: true)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()

            bottomInfoCompact
        }
    }

    // MARK: - View Components

    private var progressBar: some View {
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
    }

    private var stateIndicator: some View {
        Group {
            switch timerService.state {
            case .exerciseActive:
                stateLabel("EXERCISE", color: .blue)
            case .restPeriod:
                stateLabel("REST", color: .green)
            case .paused:
                stateLabel("PAUSED", color: .orange)
            case .completed:
                stateLabel("COMPLETED", color: .green)
            case .idle:
                EmptyView()
            }
        }
    }

    private func stateLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private var timerDisplay: some View {
        Text(timerService.formattedTime)
            .font(.system(size: 72, weight: .thin, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(timerService.state == .restPeriod ? .green : .primary)
    }

    private var timerDisplayCompact: some View {
        Text(timerService.formattedTime)
            .font(.system(size: 56, weight: .thin, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(timerService.state == .restPeriod ? .green : .primary)
    }

    private func exerciseInfo(for exercise: SessionExercise, compact: Bool) -> some View {
        let fullExercise = allExercises.first(where: { $0.id == exercise.exerciseId })

        return VStack(spacing: compact ? 8 : 12) {
            // Tactical board visualization
            if timerService.state == .exerciseActive || timerService.state == .paused,
               let fullExercise {
                TacticalBoardView(exercise: fullExercise, isCompact: true)
                    .frame(height: compact ? 100 : 140)
                    .padding(.horizontal)
            }

            if !compact {
                CategoryIconView(category: exercise.exerciseCategory, size: .large)
            }

            Text(exercise.exerciseName)
                .font(compact ? .headline : .title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(compact ? 2 : nil)

            // Exercise description (portrait only)
            if !compact,
               timerService.state == .exerciseActive || timerService.state == .paused,
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

                // Skip rest (visible during rest)
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
            timeAdjustmentButtons
        }
    }

    private var controlButtonsCompact: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if timerService.state == .exerciseActive,
                       let exercise = timerService.currentExercise {
                        isSkipping = true
                        exerciseToRate = exercise
                    } else {
                        timerService.skip()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed)

                Button {
                    if timerService.state == .paused {
                        timerService.resume()
                    } else {
                        timerService.pause()
                    }
                } label: {
                    Image(systemName: timerService.state == .paused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed)

                Button {
                    timerService.skip()
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.secondaryBackground)
                        .clipShape(Circle())
                }
                .disabled(timerService.state == .completed || timerService.state != .restPeriod)
                .opacity(timerService.state == .restPeriod ? 1 : 0.3)
            }

            timeAdjustmentButtons
        }
    }

    private var timeAdjustmentButtons: some View {
        HStack(spacing: 16) {
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

    private var bottomInfoCompact: some View {
        HStack {
            Label("\(timerService.currentExerciseIndex + 1)/\(session.exercises.count)", systemImage: "list.bullet")
            Spacer()
            Label(timerService.formattedElapsedTime, systemImage: "clock")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
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
                    VoiceAnnouncementService.shared.announceRestStart(
                        nextExerciseName: timerService.nextExercise?.exerciseName
                    )
                case .restPeriod:
                    TimerAlertService.shared.playRestCompleteAlert()
                    if let exercise = timerService.currentExercise {
                        VoiceAnnouncementService.shared.announceExerciseStart(name: exercise.exerciseName)
                    }
                default:
                    break
                }
            }
        }

        // Announce session start
        VoiceAnnouncementService.shared.announceSessionStart(
            sessionName: session.name,
            exerciseCount: session.exercises.count
        )

        timerService.start(with: session.sortedExercises)

        // Announce first exercise
        if let firstExercise = timerService.currentExercise {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                VoiceAnnouncementService.shared.announceExerciseStart(name: firstExercise.exerciseName)
            }
        }
    }

    private func handleCountdown(_ seconds: Int) {
        // Play countdown warning ticks and voice in the last 3 seconds
        if seconds <= 3 && seconds > 0 && seconds != lastCountdownWarning {
            lastCountdownWarning = seconds
            Task { @MainActor in
                TimerAlertService.shared.playCountdownWarning()
                VoiceAnnouncementService.shared.announceCountdown(seconds)
            }
        } else if seconds > 3 {
            lastCountdownWarning = 0
        }
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
            Task { @MainActor in
                TimerAlertService.shared.playSessionCompleteAlert()
                VoiceAnnouncementService.shared.announceSessionComplete()
            }

            if let exercise = session.sortedExercises.last,
               pendingRatings[exercise.exerciseId] == nil {
                exerciseToRate = exercise
            } else {
                endSession(completed: true)
            }
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Record when we went to background
            backgroundedAt = Date()
            // Schedule notification for timer completion
            scheduleBackgroundNotification()

        case .active:
            // Cancel any pending notifications
            cancelBackgroundNotifications()

            // Calculate elapsed time while in background
            if let backgroundedAt = backgroundedAt {
                let elapsedWhileBackground = Int(Date().timeIntervalSince(backgroundedAt))
                timerService.advanceTime(by: elapsedWhileBackground)
                self.backgroundedAt = nil
            }

        case .inactive:
            break

        @unknown default:
            break
        }
    }

    private func scheduleBackgroundNotification() {
        guard timerService.state == .exerciseActive || timerService.state == .restPeriod else { return }

        let content = UNMutableNotificationContent()
        content.title = timerService.state == .exerciseActive ? "Exercise Complete" : "Rest Over"
        content.body = timerService.state == .exerciseActive
            ? "Time for a rest break!"
            : "Ready for the next exercise: \(timerService.nextExercise?.exerciseName ?? "Continue")"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, timerService.remainingSeconds)),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "workout-timer-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelBackgroundNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("workout-timer-") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
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
            HStack {
                Text("Rate Exercise")
                    .font(.headline)
                Spacer()
            }
            .padding(.bottom, 8)

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

            Text(ratingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(height: 20)

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
