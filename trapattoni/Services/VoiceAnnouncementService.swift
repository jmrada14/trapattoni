import Foundation
import AVFoundation

@MainActor
final class VoiceAnnouncementService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceAnnouncementService()

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isEnabled: Bool = true

    private override init() {
        super.init()
        synthesizer.delegate = self
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

    /// Announce the start of an exercise
    func announceExerciseStart(name: String) {
        speak(name)
    }

    /// Announce transitioning to rest period
    func announceRestStart(nextExerciseName: String?) {
        if let next = nextExerciseName {
            speak("Rest. Next up: \(next)")
        } else {
            speak("Rest")
        }
    }

    /// Announce countdown (e.g., "3, 2, 1")
    func announceCountdown(_ seconds: Int) {
        speak("\(seconds)", rate: 0.6)
    }

    /// Announce session completion
    func announceSessionComplete() {
        speak("Workout complete. Great job!")
    }

    /// Announce session starting
    func announceSessionStart(sessionName: String, exerciseCount: Int) {
        speak("Starting \(sessionName). \(exerciseCount) exercises.")
    }

    /// Announce current progress
    func announceProgress(currentExercise: Int, totalExercises: Int) {
        speak("Exercise \(currentExercise) of \(totalExercises)")
    }

    // MARK: - Core Speech

    func speak(_ text: String, rate: Float = 0.52) {
        guard isEnabled else { return }

        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.9

        // Use a clear voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // Speech finished
    }
}
