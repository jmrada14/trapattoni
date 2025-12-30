import Foundation
import AVFoundation

final class VoiceAnnouncementService: @unchecked Sendable {
    static let shared = VoiceAnnouncementService()

    private let synthesizer = AVSpeechSynthesizer()
    private var _isEnabled: Bool = true
    private let lock = NSLock()

    var isEnabled: Bool {
        get { lock.withLock { _isEnabled } }
        set { lock.withLock { _isEnabled = newValue } }
    }

    private var currentLanguage: AppLanguage {
        LocalizationManager.shared.currentLanguage
    }

    private init() {
        configureAudioSession()
    }

    // MARK: - Configuration

    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .voicePrompt,
                options: [.mixWithOthers, .duckOthers]
            )
        } catch {
            print("Failed to configure audio session for voice: \(error)")
        }
        #endif
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            stop()
        }
    }

    // MARK: - Announcements

    func announceExerciseStart(name: String) {
        guard !name.isEmpty else { return }
        speak(name)
    }

    func announceRestStart(nextExerciseName: String?) {
        let restText = "voice.rest".localized
        if let next = nextExerciseName, !next.isEmpty {
            let nextText = "voice.next".localized
            speak("\(restText). \(nextText): \(next)")
        } else {
            speak(restText)
        }
    }

    func announceCountdown(_ seconds: Int) {
        guard seconds > 0 else { return }
        speak("\(seconds)", rate: 0.4)
    }

    func announceSessionComplete() {
        speak("voice.workoutComplete".localized)
    }

    func announceSessionStart(sessionName: String, exerciseCount: Int) {
        let startingText = "voice.starting".localized
        let exercisesText = "voice.exercises".localized
        let name = sessionName.isEmpty ? "workout" : sessionName
        speak("\(startingText) \(name). \(exerciseCount) \(exercisesText).")
    }

    func announceProgress(currentExercise: Int, totalExercises: Int) {
        let exerciseText = "session.exercise".localized
        speak("\(exerciseText) \(currentExercise) / \(totalExercises)")
    }

    // MARK: - Core Speech

    func speak(_ text: String, rate: Float = 0.45) {
        guard isEnabled else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        DispatchQueue.main.async { [self] in
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }

            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = rate
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.9

            // Use voice matching the selected language
            if let voice = AVSpeechSynthesisVoice(language: currentLanguage.voiceLanguageCode) {
                utterance.voice = voice
            }

            synthesizer.speak(utterance)
        }
    }

    func stop() {
        DispatchQueue.main.async { [self] in
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
}
