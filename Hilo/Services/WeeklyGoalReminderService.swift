import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class WeeklyGoalReminderService {
    static let shared = WeeklyGoalReminderService { start, end in
        try await CalendarService.shared.getWeeklyReadPages(startDate: start, endDate: end)
    }
    static let requestIDs = ["hilo.reading.weekly.3", "hilo.reading.weekly.6"]
    private(set) var showsOnHome = true
    private(set) var enabled = false
    private(set) var targetPages = 100
    private(set) var progress: WeeklyReadingGoal?
    private(set) var scheduledDates: [Date] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var requestingPermission = false
    private(set) var permissionGranted = false
    private var userID: UUID?
    private var hour = 20
    private var minute = 0
    private var revision = 0
    private var fetchVersion = 0
    private var worker: Task<Void, Never>?
    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let now: () -> Date
    // A half-open date interval [Monday, next Monday), scoped to the authenticated account.
    private let fetchPages: (Date, Date) async throws -> Int

    init(defaults: UserDefaults = .standard, center: UNUserNotificationCenter? = nil,
         now: @escaping () -> Date = Date.init,
         fetchPages: @escaping (Date, Date) async throws -> Int) {
        self.defaults = defaults
        self.center = center ?? .current()
        self.now = now
        self.fetchPages = fetchPages
    }

    private func key(_ suffix: String) -> String { "weeklyGoal.\(userID!.uuidString).\(suffix)" }

    func setUser(_ id: UUID?) {
        if userID == id {
            if id == nil { cancel(); reconcile() }
            return
        }
        cancel()
        userID = id
        fetchVersion += 1
        isLoading = false
        progress = nil
        errorMessage = nil
        showsOnHome = id == nil ? true : (defaults.object(forKey: key("showsOnHome")) as? Bool ?? true)
        enabled = id != nil && defaults.bool(forKey: key("enabled"))
        let saved = id == nil ? 100 : defaults.integer(forKey: key("target"))
        targetPages = (10...5000).contains(saved) ? saved : 100
        reconcile()
    }

    func setShowsOnHome(_ value: Bool) {
        guard userID != nil else { return }
        showsOnHome = value
        defaults.set(value, forKey: key("showsOnHome"))
    }

    func setTarget(_ pages: Int) {
        guard userID != nil, (10...5000).contains(pages) else { return }
        targetPages = pages
        defaults.set(pages, forKey: key("target"))
        if let progress {
            self.progress = WeeklyReadingGoal(targetPages: pages, pagesRead: progress.pagesRead, weekStart: progress.weekStart)
        }
        reconcile()
    }

    func setTime(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return }
        self.hour = hour
        self.minute = minute
        reconcile()
    }

    func setEnabled(_ value: Bool) async {
        guard let account = userID, !requestingPermission else { return }
        enabled = value
        defaults.set(value, forKey: key("enabled"))
        cancel()
        reconcile()
        guard value else { return }
        requestingPermission = true
        defer { requestingPermission = false }
        do {
            let settings = await center.notificationSettings()
            guard userID == account else { return }
            if settings.authorizationStatus == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
            }
            guard userID == account else { return }
            await refresh()
        } catch {
            guard userID == account else { return }
            errorMessage = String(localized: "reminders_permission_error")
        }
        reconcile()
    }

    /// Called on launch/foreground and after a successful progress mutation.
    /// Suspend requests while refreshing so an old total cannot trigger a misleading reminder.
    func refresh() async {
        guard let account = userID else { return }
        fetchVersion += 1
        let version = fetchVersion
        let weekStart = WeeklyReadingGoal.start(of: now())
        let weekEnd = WeeklyReadingGoal.calendar.date(byAdding: .day, value: 7, to: weekStart)!
        isLoading = true
        progress = nil
        cancel()
        reconcile()
        do {
            let pages = try await fetchPages(weekStart, weekEnd)
            guard userID == account, version == fetchVersion else { return }
            isLoading = false
            guard WeeklyReadingGoal.start(of: now()) == weekStart else {
                await refresh()
                return
            }
            guard pages >= 0 else { throw CocoaError(.coderInvalidValue) }
            progress = WeeklyReadingGoal(targetPages: targetPages, pagesRead: pages, weekStart: weekStart)
            errorMessage = nil
        } catch {
            guard userID == account, version == fetchVersion else { return }
            isLoading = false
            errorMessage = String(localized: "weekly_goal_load_error")
        }
        reconcile()
    }

    func reconcile() {
        revision += 1
        guard worker == nil else { return }
        worker = Task {
            var processed = -1
            while processed != revision {
                processed = revision
                let settings = await center.notificationSettings()
                guard processed == revision else { continue }
                permissionGranted = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
                cancel()
                guard userID != nil, enabled, permissionGranted, !isLoading, let progress else { continue }
                for checkpoint in progress.checkpoints(after: now(), hour: hour, minute: minute) {
                    guard processed == revision else { break }
                    let content = UNMutableNotificationContent()
                    content.title = String(localized: "weekly_goal_notification_title")
                    content.body = String(localized: "weekly_goal_notification_body")
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: WeeklyReadingGoal.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: checkpoint.date),
                        repeats: false
                    )
                    do {
                        try await center.add(UNNotificationRequest(
                            identifier: "hilo.reading.weekly.\(checkpoint.day)", content: content, trigger: trigger
                        ))
                        if processed == revision { scheduledDates.append(checkpoint.date) }
                    } catch {
                        if processed == revision { errorMessage = String(localized: "reminders_schedule_error") }
                    }
                }
            }
            worker = nil
        }
    }

    private func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: Self.requestIDs)
        center.removeDeliveredNotifications(withIdentifiers: Self.requestIDs)
        scheduledDates = []
    }
}
