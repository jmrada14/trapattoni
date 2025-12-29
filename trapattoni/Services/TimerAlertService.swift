import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class TimerAlertService {
    static let shared = TimerAlertService()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        configureAudioSession()
    }

    // MARK: - Screen Wake

    /// Prevent screen from dimming during workout
    func keepScreenAwake(_ awake: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = awake
        #endif
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
    }

    // MARK: - Alerts

    /// Play alert for exercise completion (transitioning to rest)
    func playExerciseCompleteAlert() {
        playSystemSound(.exerciseComplete)
        triggerHaptic(.success)
    }

    /// Play alert for rest period completion (transitioning to next exercise)
    func playRestCompleteAlert() {
        playSystemSound(.restComplete)
        triggerHaptic(.warning)
    }

    /// Play alert for session completion
    func playSessionCompleteAlert() {
        playSystemSound(.sessionComplete)
        triggerHaptic(.success)
    }

    /// Play countdown warning (e.g., 3 seconds remaining)
    func playCountdownWarning() {
        playSystemSound(.tick)
        triggerHaptic(.light)
    }

    // MARK: - Sound Types

    enum SoundType {
        case exerciseComplete   // End of exercise
        case restComplete       // End of rest period
        case sessionComplete    // Entire session finished
        case tick               // Countdown tick

        var systemSoundID: SystemSoundID {
            switch self {
            case .exerciseComplete:
                return 1007  // SMS received tone
            case .restComplete:
                return 1005  // Alarm sound
            case .sessionComplete:
                return 1025  // Success fanfare
            case .tick:
                return 1057  // Tock sound
            }
        }
    }

    // MARK: - Haptic Types

    enum HapticType {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
    }

    // MARK: - Private Methods

    private func playSystemSound(_ sound: SoundType) {
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }

    private func triggerHaptic(_ type: HapticType) {
        #if os(iOS)
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
        #endif
    }
}
