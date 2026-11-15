import Foundation
import Observation
import UserNotifications

/// Daily and one-shot inactivity reminders; preferences and activity are scoped per account.
@MainActor
@Observable
final class ReadingReminderService {
    static let shared = ReadingReminderService()
    static let inactivityRequestID = "hilo.reading.inactivity"
    static let requestID = "hilo.reading.daily"

    private(set) var enabled = false
    private(set) var hour = 20
    private(set) var minute = 0
    private(set) var hasActiveReading = false
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    private(set) var scheduled = false
    private(set) var errorMessage: String?
    private(set) var requestingPermission = false
    private(set) var inactivityEnabled = false
    private(set) var inactivityDays = 3
    private(set) var lastReadingActivity: Date?
    private(set) var inactivityScheduledDate: Date?
    private(set) var activityError: String?
    private var activityKnown = false
    private var inactivityAnchor: Date?
    private var inactivityTarget: Date?
    private var activityVersion = 0
    private let fetchActivity: () async throws -> Date?
    private let now: () -> Date
    private var userID: UUID?
    private let defaults: UserDefaults
    private let center: UNUserNotificationCenter
    private var revision = 0
    private var worker: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, center: UNUserNotificationCenter? = nil,
         now: @escaping () -> Date = Date.init,
         fetchActivity: @escaping () async throws -> Date? = { try await CalendarService.shared.getLastReadingActivity() }) {
        self.now = now
        self.fetchActivity = fetchActivity
        self.defaults = defaults
        self.center = center ?? .current()
    }

    var time: Date {
        Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? Date()
    }

    private func key(_ suffix: String) -> String {
        "readingReminder.\(userID!.uuidString).\(suffix)"
    }

    func setUser(_ id: UUID?) {
        guard userID != id else {
            // A restored signed-out session must also clear requests from a previous launch.
            if id == nil { cancel(); reconcile() }
            return
        }
        cancel()
        userID = id
        activityVersion += 1
        activityError = nil
        inactivityEnabled = id != nil && defaults.bool(forKey: key("inactivityEnabled"))
        inactivityDays = id == nil ? 3 : (defaults.object(forKey: key("inactivityDays")) as? Int ?? 3)
        lastReadingActivity = id == nil ? nil : defaults.object(forKey: key("lastActivity")) as? Date
        inactivityAnchor = id == nil ? nil : defaults.object(forKey: key("inactivityAnchor")) as? Date
        inactivityTarget = id == nil ? nil : defaults.object(forKey: key("inactivityTarget")) as? Date
        activityKnown = id != nil && defaults.bool(forKey: key("activityKnown"))
        enabled = id != nil && defaults.bool(forKey: key("enabled"))
        hasActiveReading = id != nil && defaults.bool(forKey: key("active"))
        hour = id == nil ? 20 : (defaults.object(forKey: key("hour")) as? Int ?? 20)
        minute = id == nil ? 0 : defaults.integer(forKey: key("minute"))
        reconcile()
    }

    func updateLibrary(userID: UUID, hasActiveReading: Bool) {
        guard self.userID == userID else { return }
        self.hasActiveReading = hasActiveReading
        defaults.set(hasActiveReading, forKey: key("active"))
        reconcile()
    }

    func setEnabled(_ value: Bool, inactivity: Bool = false) async {
        guard let account = userID, !requestingPermission else { return }
        if inactivity {
            inactivityEnabled = value
            defaults.set(value, forKey: key("inactivityEnabled"))
            if value && lastReadingActivity == nil {
                inactivityAnchor = now()
                defaults.set(inactivityAnchor, forKey: key("inactivityAnchor"))
            }
            resetInactivityTarget()
        } else {
            enabled = value
            defaults.set(value, forKey: key("enabled"))
        }
        if !value { cancel() }
        if value {
            requestingPermission = true
            defer { requestingPermission = false }
            let settings = await center.notificationSettings()
            guard userID == account else { return }
            if settings.authorizationStatus == .notDetermined {
                do {
                    _ = try await center.requestAuthorization(options: [.alert, .sound])
                } catch {
                    guard userID == account else { return }
                    if inactivity { inactivityEnabled = false } else { enabled = false }
                    defaults.set(false, forKey: key(inactivity ? "inactivityEnabled" : "enabled"))
                    errorMessage = String(localized: "reminders_permission_error")
                    return
                }
            }
        }
        reconcile()
        if inactivity && value { await refreshActivity() }
    }

    func setTime(_ date: Date) {
        guard userID != nil else { return }
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        hour = parts.hour ?? 20
        minute = parts.minute ?? 0
        defaults.set(hour, forKey: key("hour"))
        defaults.set(minute, forKey: key("minute"))
        resetInactivityTarget()
        reconcile()
    }

    /// Serializes async scheduling. A change during an OS call is reconciled again,
    /// so an in-flight add cannot leave a reminder behind after logout or disabling.
    func reconcile() {
        revision += 1
        guard worker == nil else { return }
        worker = Task {
            var processed = -1
            while processed != revision {
                processed = revision
                let settings = await center.notificationSettings()
                guard processed == revision else { continue }
                authorization = settings.authorizationStatus
                errorMessage = nil
                cancel()
                guard userID != nil,
                      [.authorized, .provisional, .ephemeral].contains(authorization) else { continue }
                if enabled && hasActiveReading {
                    let content = UNMutableNotificationContent()
                    content.title = String(localized: "reminders_notification_title")
                    content.body = String(localized: "reminders_notification_body")
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: DateComponents(hour: hour, minute: minute), repeats: true
                    )
                    do {
                        try await center.add(UNNotificationRequest(
                            identifier: Self.requestID, content: content, trigger: trigger
                        ))
                        if processed == revision { scheduled = true }
                    } catch {
                        if processed == revision { errorMessage = String(localized: "reminders_schedule_error") }
                    }
                }
                guard processed == revision else { continue }
                if inactivityEnabled && activityKnown, let target = inactivityDate(), target > now() {
                    let content = UNMutableNotificationContent()
                    content.title = String(localized: "inactivity_notification_title")
                    content.body = String(localized: "inactivity_notification_body")
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: target),
                        repeats: false
                    )
                    do {
                        try await center.add(UNNotificationRequest(
                            identifier: Self.inactivityRequestID, content: content, trigger: trigger
                        ))
                        if processed == revision { inactivityScheduledDate = target }
                    } catch {
                        if processed == revision {
                            resetInactivityTarget()
                            errorMessage = String(localized: "reminders_schedule_error")
                        }
                    }
                }
            }
            worker = nil
        }
    }

    func setInactivityDays(_ days: Int) {
        guard userID != nil, [3, 7].contains(days) else { return }
        inactivityDays = days
        defaults.set(days, forKey: key("inactivityDays"))
        resetInactivityTarget()
        reconcile()
    }

    func refreshActivity() async {
        guard let account = userID else { return }
        activityVersion += 1
        let version = activityVersion
        do {
            let date = try await fetchActivity()
            guard userID == account, version == activityVersion else { return }
            activityError = nil
            activityKnown = true
            defaults.set(true, forKey: key("activityKnown"))
            if let date { recordActivity(userID: account, at: date) }
            reconcile()
        } catch {
            guard userID == account, version == activityVersion else { return }
            activityError = String(localized: "inactivity_load_error")
        }
    }

    func recordActivity(userID: UUID, at date: Date) {
        guard self.userID == userID, date <= now(),
              lastReadingActivity == nil || date > lastReadingActivity! else { return }
        lastReadingActivity = date
        activityKnown = true
        defaults.set(date, forKey: key("lastActivity"))
        defaults.set(true, forKey: key("activityKnown"))
        resetInactivityTarget()
        reconcile()
    }

    private func resetInactivityTarget() {
        inactivityTarget = nil
        inactivityScheduledDate = nil
        if userID != nil { defaults.removeObject(forKey: key("inactivityTarget")) }
    }

    private func inactivityDate() -> Date? {
        if let inactivityTarget { return inactivityTarget }
        guard let baseline = lastReadingActivity ?? inactivityAnchor else { return nil }
        let calendar = Calendar.current
        guard let day = calendar.date(byAdding: .day, value: inactivityDays, to: calendar.startOfDay(for: baseline)),
              var target = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { return nil }
        if target <= now() {
            guard let next = calendar.nextDate(after: now(), matching: DateComponents(hour: hour, minute: minute), matchingPolicy: .nextTime) else { return nil }
            target = next
        }
        inactivityTarget = target
        defaults.set(target, forKey: key("inactivityTarget"))
        return target
    }

    private func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID, Self.inactivityRequestID])
        center.removeDeliveredNotifications(withIdentifiers: [Self.requestID, Self.inactivityRequestID])
        scheduled = false
        inactivityScheduledDate = nil
    }
}
