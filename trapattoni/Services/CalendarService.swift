import Foundation
import EventKit

@MainActor
class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    /// URL scheme for deep linking back to the app
    static let appURLScheme = "trapattoni"

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        let status = checkPermissionStatus()

        switch status {
        case .authorized:
            return true
        case .fullAccess:
            return true
        case .notDetermined:
            return await requestAccess()
        case .denied, .restricted, .writeOnly:
            return false
        @unknown default:
            return false
        }
    }

    private func requestAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                print("Calendar permission error: \(error)")
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func checkPermissionStatus() -> EKAuthorizationStatus {
        return EKEventStore.authorizationStatus(for: .event)
    }

    var isCalendarAvailable: Bool {
        let status = checkPermissionStatus()
        if #available(iOS 17.0, macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    // MARK: - Event Creation

    /// Creates a calendar event for the given activity
    /// - Parameters:
    ///   - activity: The scheduled activity to create an event for
    ///   - reminderMinutes: Minutes before event to set alarm (default 15)
    /// - Returns: The event identifier if successful, nil otherwise
    func createEvent(
        for activity: ScheduledActivity,
        reminderMinutes: Int = 15
    ) async -> String? {
        guard isCalendarAvailable else { return nil }
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            print("No default calendar available")
            return nil
        }

        let event = EKEvent(eventStore: eventStore)
        configureEvent(event, from: activity, calendar: calendar, reminderMinutes: reminderMinutes)

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            print("Failed to create calendar event: \(error)")
            return nil
        }
    }

    /// Creates a recurring calendar event
    /// - Parameters:
    ///   - activity: The first activity in the series
    ///   - recurrenceType: The recurrence pattern
    ///   - endDate: Optional end date for the recurrence
    ///   - reminderMinutes: Minutes before event to set alarm
    /// - Returns: The event identifier if successful, nil otherwise
    func createRecurringEvent(
        for activity: ScheduledActivity,
        recurrenceType: RecurrenceType,
        endDate: Date?,
        reminderMinutes: Int = 15
    ) async -> String? {
        guard isCalendarAvailable else { return nil }
        guard let calendar = eventStore.defaultCalendarForNewEvents else {
            print("No default calendar available")
            return nil
        }

        let event = EKEvent(eventStore: eventStore)
        configureEvent(event, from: activity, calendar: calendar, reminderMinutes: reminderMinutes)

        // Add recurrence rule
        if let rule = createRecurrenceRule(for: recurrenceType, endDate: endDate) {
            event.addRecurrenceRule(rule)
        }

        do {
            try eventStore.save(event, span: .futureEvents)
            return event.eventIdentifier
        } catch {
            print("Failed to create recurring calendar event: \(error)")
            return nil
        }
    }

    // MARK: - Event Update

    /// Updates an existing calendar event with new activity data
    func updateEvent(for activity: ScheduledActivity) async -> Bool {
        guard isCalendarAvailable else { return false }
        guard let eventId = activity.calendarEventId,
              let event = eventStore.event(withIdentifier: eventId) else {
            return false
        }

        // Update event properties
        event.title = activity.title
        event.startDate = activity.scheduledDate
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: activity.durationMinutes,
            to: activity.scheduledDate
        )
        event.location = activity.location.isEmpty ? nil : activity.location
        event.notes = buildEventNotes(for: activity)

        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to update calendar event: \(error)")
            return false
        }
    }

    // MARK: - Event Existence Check

    /// Checks if a calendar event still exists (for detecting external deletion)
    func eventExists(eventIdentifier: String) -> Bool {
        guard isCalendarAvailable else { return false }
        return eventStore.event(withIdentifier: eventIdentifier) != nil
    }

    /// Refreshes the event store to get latest changes from Calendar app
    func refreshEventStore() {
        eventStore.refreshSourcesIfNecessary()
    }

    // MARK: - Private Helpers

    private func configureEvent(
        _ event: EKEvent,
        from activity: ScheduledActivity,
        calendar: EKCalendar,
        reminderMinutes: Int
    ) {
        event.title = activity.title
        event.startDate = activity.scheduledDate
        event.endDate = Calendar.current.date(
            byAdding: .minute,
            value: activity.durationMinutes,
            to: activity.scheduledDate
        )
        event.calendar = calendar
        event.location = activity.location.isEmpty ? nil : activity.location
        event.notes = buildEventNotes(for: activity)

        // Deep link URL to open activity in app
        event.url = URL(string: "\(Self.appURLScheme)://activity/\(activity.id.uuidString)")

        // Add reminder alarm
        event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-reminderMinutes * 60)))
    }

    private func buildEventNotes(for activity: ScheduledActivity) -> String {
        var notes = ""

        // Add activity type indicator with emoji
        let typeIndicator = activityTypeIndicator(activity.activityType)
        notes += "\(typeIndicator)\n\n"

        // Add user notes if any
        if !activity.notes.isEmpty {
            notes += activity.notes
            notes += "\n\n"
        }

        // Add deep link info
        notes += "---\nOpen in Trapattoni"

        return notes
    }

    private func activityTypeIndicator(_ type: ActivityType) -> String {
        switch type {
        case .training: return "⚽️ Training Session"
        case .gym: return "🏋️ Gym Workout"
        case .game: return "🏆 Game Day"
        case .recovery: return "🧘 Recovery"
        case .cardio: return "🏃 Cardio"
        }
    }

    // MARK: - Event Deletion

    /// Deletes a single calendar event by its identifier
    func deleteEvent(eventIdentifier: String) async {
        guard isCalendarAvailable else { return }

        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            print("Calendar event not found: \(eventIdentifier)")
            return
        }

        do {
            try eventStore.remove(event, span: .thisEvent)
        } catch {
            print("Failed to delete calendar event: \(error)")
        }
    }

    /// Deletes a recurring event and all its future occurrences
    func deleteRecurringEvent(eventIdentifier: String) async {
        guard isCalendarAvailable else { return }

        guard let event = eventStore.event(withIdentifier: eventIdentifier) else {
            print("Calendar event not found: \(eventIdentifier)")
            return
        }

        do {
            try eventStore.remove(event, span: .futureEvents)
        } catch {
            print("Failed to delete recurring calendar event: \(error)")
        }
    }

    /// Deletes multiple calendar events
    func deleteEvents(eventIdentifiers: [String]) async {
        for identifier in eventIdentifiers {
            await deleteEvent(eventIdentifier: identifier)
        }
    }

    // MARK: - Recurrence Mapping

    private func createRecurrenceRule(
        for type: RecurrenceType,
        endDate: Date?
    ) -> EKRecurrenceRule? {
        let recurrenceEnd: EKRecurrenceEnd?
        if let endDate = endDate {
            recurrenceEnd = EKRecurrenceEnd(end: endDate)
        } else {
            recurrenceEnd = nil
        }

        switch type {
        case .none:
            return nil
        case .daily:
            return EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: 1,
                end: recurrenceEnd
            )
        case .weekly:
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                end: recurrenceEnd
            )
        case .biweekly:
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 2,
                end: recurrenceEnd
            )
        case .monthly:
            return EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 1,
                end: recurrenceEnd
            )
        }
    }
}
