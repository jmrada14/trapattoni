import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleActivityReminder(for activity: ScheduledActivity, minutesBefore: Int = 15) async {
        let status = await checkPermissionStatus()
        guard status == .authorized else { return }

        // Remove any existing notification for this activity
        removeNotification(for: activity.id)

        // Calculate notification time
        guard let notificationDate = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: activity.scheduledDate),
              notificationDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Training Reminder"
        content.body = "\(activity.title) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "TRAINING_REMINDER"

        // Add activity info to userInfo for handling taps
        content.userInfo = [
            "activityId": activity.id.uuidString,
            "activityType": activity.activityTypeRaw
        ]

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: activity.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(activity.title) at \(notificationDate)")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func scheduleMultipleReminders(for activity: ScheduledActivity) async {
        // Schedule 15 minutes before
        await scheduleActivityReminder(for: activity, minutesBefore: 15)

        // Also schedule 1 hour before if there's time
        let oneHourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: activity.scheduledDate) ?? activity.scheduledDate
        if oneHourBefore > Date() {
            await scheduleHourBeforeReminder(for: activity)
        }
    }

    private func scheduleHourBeforeReminder(for activity: ScheduledActivity) async {
        guard let notificationDate = Calendar.current.date(byAdding: .hour, value: -1, to: activity.scheduledDate),
              notificationDate > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Training"
        content.body = "\(activity.title) in 1 hour"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: notificationDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "\(activity.id.uuidString)-1h",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule 1h notification: \(error)")
        }
    }

    // MARK: - Remove Notifications

    func removeNotification(for activityId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [activityId.uuidString, "\(activityId.uuidString)-1h"]
        )
    }

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - List Pending

    func listPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    // MARK: - Smart Reminders

    private let inactivityReminderId = "smart-inactivity-reminder"
    private let weeklyGoalReminderId = "smart-weekly-goal-reminder"

    /// Updates all smart reminders based on current profile settings and training data
    func updateSmartReminders(
        profile: PlayerProfile,
        lastTrainingDate: Date?,
        sessionsThisWeek: Int
    ) async {
        let status = await checkPermissionStatus()
        guard status == .authorized, profile.notificationsEnabled else {
            removeSmartReminders()
            return
        }

        // Schedule inactivity reminder if enabled
        if profile.inactivityRemindersEnabled {
            await scheduleInactivityReminder(
                profile: profile,
                lastTrainingDate: lastTrainingDate
            )
        } else {
            removeNotificationById(inactivityReminderId)
        }

        // Schedule weekly goal reminder if enabled
        if profile.weeklyGoalRemindersEnabled {
            await scheduleWeeklyGoalReminder(
                profile: profile,
                sessionsThisWeek: sessionsThisWeek
            )
        } else {
            removeNotificationById(weeklyGoalReminderId)
        }
    }

    /// Schedules a reminder if the user hasn't trained recently
    private func scheduleInactivityReminder(
        profile: PlayerProfile,
        lastTrainingDate: Date?
    ) async {
        removeNotificationById(inactivityReminderId)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate days since last training
        let daysSinceTraining: Int
        if let lastDate = lastTrainingDate {
            let lastTrainingDay = calendar.startOfDay(for: lastDate)
            daysSinceTraining = calendar.dateComponents([.day], from: lastTrainingDay, to: today).day ?? 0
        } else {
            daysSinceTraining = profile.inactivityDaysThreshold // Assume they need a reminder if no history
        }

        // Only schedule if they've been inactive long enough
        guard daysSinceTraining >= profile.inactivityDaysThreshold else { return }

        // Schedule for tomorrow at reminder time
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = profile.reminderHour
        components.minute = profile.reminderMinute

        let content = UNMutableNotificationContent()
        content.title = "Time to Train!"
        if daysSinceTraining == 1 {
            content.body = "You haven't trained since yesterday. Ready to get back at it?"
        } else {
            content.body = "It's been \(daysSinceTraining) days since your last session. Let's get moving!"
        }
        content.sound = .default
        content.categoryIdentifier = "INACTIVITY_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: inactivityReminderId,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule inactivity reminder: \(error)")
        }
    }

    /// Schedules a reminder about weekly goal progress
    private func scheduleWeeklyGoalReminder(
        profile: PlayerProfile,
        sessionsThisWeek: Int
    ) async {
        removeNotificationById(weeklyGoalReminderId)

        let calendar = Calendar.current
        let today = Date()

        // Get current weekday (1 = Sunday, 7 = Saturday)
        let weekday = calendar.component(.weekday, from: today)

        // Only send goal reminders mid-week (Wednesday-Friday) or weekend
        // Early week they have time, late week they need a push
        guard weekday >= 4 else { return } // Wednesday or later

        let sessionsRemaining = profile.weeklyGoalSessions - sessionsThisWeek

        // Don't remind if they've already hit their goal
        guard sessionsRemaining > 0 else { return }

        // Schedule for tomorrow at reminder time
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) else { return }
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = profile.reminderHour
        components.minute = profile.reminderMinute

        let content = UNMutableNotificationContent()

        // Craft message based on how close they are
        if sessionsRemaining == 1 {
            content.title = "Almost There!"
            content.body = "Just 1 more session to hit your weekly goal. You've got this!"
        } else if weekday >= 6 { // Friday or later - urgent
            content.title = "Weekend Push!"
            content.body = "\(sessionsRemaining) sessions left to reach your goal of \(profile.weeklyGoalSessions) this week."
        } else {
            content.title = "Weekly Goal Check-in"
            content.body = "You've completed \(sessionsThisWeek)/\(profile.weeklyGoalSessions) sessions this week. Keep it up!"
        }

        content.sound = .default
        content.categoryIdentifier = "WEEKLY_GOAL_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: weeklyGoalReminderId,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule weekly goal reminder: \(error)")
        }
    }

    /// Removes all smart reminders
    func removeSmartReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [inactivityReminderId, weeklyGoalReminderId]
        )
    }

    private func removeNotificationById(_ identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }
}
