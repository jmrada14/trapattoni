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
}
