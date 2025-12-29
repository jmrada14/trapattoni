import Foundation
import Observation

@Observable
final class SessionTimerService {
    enum TimerState: Equatable {
        case idle
        case exerciseActive
        case restPeriod
        case paused
        case completed
    }

    // MARK: - Published State

    private(set) var state: TimerState = .idle
    private(set) var currentExerciseIndex: Int = 0
    private(set) var remainingSeconds: Int = 0
    private(set) var totalElapsedSeconds: Int = 0

    // MARK: - Private State

    private var timer: Timer?
    private var exercises: [SessionExercise] = []
    private var isInRestPeriod = false
    private var pausedState: TimerState = .idle

    // MARK: - Computed Properties

    var currentExercise: SessionExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var nextExercise: SessionExercise? {
        let nextIndex = currentExerciseIndex + 1
        guard nextIndex < exercises.count else { return nil }
        return exercises[nextIndex]
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        let baseProgress = Double(currentExerciseIndex) / Double(exercises.count)

        if let current = currentExercise {
            let totalForExercise = current.durationSeconds + current.restAfterSeconds
            let completedForExercise: Int

            if isInRestPeriod {
                completedForExercise = current.durationSeconds + (current.restAfterSeconds - remainingSeconds)
            } else {
                completedForExercise = current.durationSeconds - remainingSeconds
            }

            let exerciseProgress = Double(completedForExercise) / Double(max(totalForExercise, 1))
            return baseProgress + (exerciseProgress / Double(exercises.count))
        }

        return baseProgress
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedElapsedTime: String {
        let minutes = totalElapsedSeconds / 60
        let seconds = totalElapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var exercisesRemaining: Int {
        max(0, exercises.count - currentExerciseIndex)
    }

    var isLastExercise: Bool {
        currentExerciseIndex == exercises.count - 1
    }

    // MARK: - Public Methods

    func start(with exercises: [SessionExercise]) {
        self.exercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
        self.currentExerciseIndex = 0
        self.totalElapsedSeconds = 0
        self.isInRestPeriod = false

        startExercise()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        pausedState = state
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        state = pausedState
        startTimer()
    }

    func skip() {
        timer?.invalidate()
        timer = nil

        if isInRestPeriod {
            moveToNextExercise()
        } else {
            // Skip to rest period or next exercise if no rest
            if let current = currentExercise, current.restAfterSeconds > 0 {
                startRestPeriod()
            } else {
                moveToNextExercise()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        exercises = []
        currentExerciseIndex = 0
        remainingSeconds = 0
    }

    func extendTime(by seconds: Int) {
        remainingSeconds += seconds
    }

    // MARK: - Private Methods

    private func startExercise() {
        guard let exercise = currentExercise else {
            state = .completed
            return
        }

        isInRestPeriod = false
        remainingSeconds = exercise.durationSeconds
        state = .exerciseActive
        startTimer()
    }

    private func startRestPeriod() {
        guard let exercise = currentExercise else {
            moveToNextExercise()
            return
        }

        guard exercise.restAfterSeconds > 0 else {
            moveToNextExercise()
            return
        }

        isInRestPeriod = true
        remainingSeconds = exercise.restAfterSeconds
        state = .restPeriod
        startTimer()
    }

    private func moveToNextExercise() {
        currentExerciseIndex += 1

        if currentExerciseIndex >= exercises.count {
            state = .completed
            timer?.invalidate()
            timer = nil
        } else {
            startExercise()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        totalElapsedSeconds += 1
        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            timer?.invalidate()
            timer = nil

            if isInRestPeriod {
                moveToNextExercise()
            } else {
                startRestPeriod()
            }
        }
    }
}
