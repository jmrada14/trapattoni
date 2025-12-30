import Foundation
import SwiftData

@Model
final class ScheduledActivity {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var activityTypeRaw: String = "training"
    var scheduledDate: Date = Date()
    var durationMinutes: Int = 60
    var isCompleted: Bool = false
    var completedAt: Date?

    // Optional link to a training session (for training type)
    var linkedSessionId: UUID?
    var linkedSessionName: String?

    // Optional link to a training plan (for bulk operations)
    var linkedPlanId: UUID?

    // Recurrence properties
    var recurrenceTypeRaw: String = "none"
    var recurrenceEndDate: Date?
    var recurrenceGroupId: UUID?  // Links recurring instances together

    // Calendar sync
    var calendarEventId: String?  // EventKit event identifier for device calendar sync

    // Location
    var location: String = ""

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Computed Properties

    var activityType: ActivityType {
        get { ActivityType(rawValue: activityTypeRaw) ?? .training }
        set { activityTypeRaw = newValue.rawValue }
    }

    var recurrenceType: RecurrenceType {
        get { RecurrenceType(rawValue: recurrenceTypeRaw) ?? .none }
        set { recurrenceTypeRaw = newValue.rawValue }
    }

    var isRecurring: Bool {
        recurrenceType != .none
    }

    var formattedDuration: String {
        if durationMinutes >= 60 {
            let hours = durationMinutes / 60
            let mins = durationMinutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        }
        return "\(durationMinutes)m"
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledDate)
    }

    // MARK: - Initializers

    init(
        title: String,
        type: ActivityType,
        scheduledDate: Date,
        durationMinutes: Int = 60,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.activityTypeRaw = type.rawValue
        self.scheduledDate = scheduledDate
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    init(
        session: TrainingSession,
        scheduledDate: Date
    ) {
        self.id = UUID()
        self.title = session.name
        self.activityTypeRaw = ActivityType.training.rawValue
        self.scheduledDate = scheduledDate
        self.durationMinutes = session.totalDurationSeconds / 60
        self.linkedSessionId = session.id
        self.linkedSessionName = session.name
        self.isCompleted = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    func markCompleted() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
        updatedAt = Date()
    }
}

// MARK: - Activity Type

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    case training = "Training"
    case gym = "Gym"
    case game = "Game"
    case recovery = "Recovery"
    case cardio = "Cardio"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .training: return "activity.training".localized
        case .gym: return "activity.gym".localized
        case .game: return "activity.game".localized
        case .recovery: return "activity.recovery".localized
        case .cardio: return "activity.cardio".localized
        }
    }

    var iconName: String {
        switch self {
        case .training: return "figure.run"
        case .gym: return "dumbbell.fill"
        case .game: return "sportscourt.fill"
        case .recovery: return "heart.circle.fill"
        case .cardio: return "figure.run.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .training: return "blue"
        case .gym: return "purple"
        case .game: return "green"
        case .recovery: return "orange"
        case .cardio: return "red"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .training: return 60
        case .gym: return 90
        case .game: return 90
        case .recovery: return 30
        case .cardio: return 45
        }
    }
}

// MARK: - Recurrence Type

enum RecurrenceType: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "recurrence.none".localized
        case .daily: return "recurrence.daily".localized
        case .weekly: return "recurrence.weekly".localized
        case .biweekly: return "recurrence.biweekly".localized
        case .monthly: return "recurrence.monthly".localized
        }
    }

    var calendarComponent: Calendar.Component? {
        switch self {
        case .none: return nil
        case .daily: return .day
        case .weekly, .biweekly: return .weekOfYear
        case .monthly: return .month
        }
    }

    var componentValue: Int {
        switch self {
        case .none: return 0
        case .daily: return 1
        case .weekly: return 1
        case .biweekly: return 2
        case .monthly: return 1
        }
    }
}
