"""Run the real reminder coordinator against an in-memory notification center."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
stubs = r'''
import Foundation
import Observation
@MainActor final class CalendarService {
    static let shared = CalendarService()
    func getLastReadingActivity() async throws -> Date? { nil }
    func getWeeklyReadPages(startDate: Date, endDate: Date) async throws -> Int { 0 }
}
enum UNAuthorizationStatus { case notDetermined, denied, authorized, provisional, ephemeral }
struct Settings { var authorizationStatus: UNAuthorizationStatus }
struct Options: OptionSet {
    let rawValue: Int
    static let alert = Options(rawValue: 1)
    static let sound = Options(rawValue: 2)
}
struct Sound { static let `default` = Sound() }
final class UNMutableNotificationContent {
    var title = ""
    var body = ""
    var sound: Sound?
}
struct UNCalendarNotificationTrigger { let dateMatching: DateComponents; let repeats: Bool }
struct UNNotificationRequest {
    let identifier: String
    let content: UNMutableNotificationContent
    let trigger: UNCalendarNotificationTrigger
}
@MainActor final class UNUserNotificationCenter {
    static func current() -> UNUserNotificationCenter { UNUserNotificationCenter() }
    var status: UNAuthorizationStatus = .notDetermined
    var pending: [String: UNNotificationRequest] = [:]
    var asks = 0
    var failAdd = false
    var pauseAdd = false
    var suspended: CheckedContinuation<Void, Never>?
    func notificationSettings() async -> Settings { Settings(authorizationStatus: status) }
    func requestAuthorization(options: Options) async throws -> Bool {
        asks += 1
        status = .authorized
        return true
    }
    func add(_ request: UNNotificationRequest) async throws {
        if pauseAdd { await withCheckedContinuation { suspended = $0 } }
        if failAdd { throw URLError(.unknown) }
        pending[request.identifier] = request
    }
    func removePendingNotificationRequests(withIdentifiers ids: [String]) {
        for id in ids { pending[id] = nil }
    }
    func removeDeliveredNotifications(withIdentifiers ids: [String]) {}
}
'''
source = (root / 'Hilo/Services/ReadingReminderService.swift').read_text().replace('import UserNotifications', '')
checks = r'''
@main struct Checks {
    @MainActor static func settle() async { try? await Task.sleep(for: .milliseconds(30)) }
    @MainActor static func main() async {
        let suite = "ReminderTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let center = UNUserNotificationCenter()
        let service = ReadingReminderService(defaults: defaults, center: center)
        let a = UUID(), b = UUID()
        let id = ReadingReminderService.requestID
        service.setUser(a)
        await settle()
        assert(center.asks == 0 && center.pending.isEmpty)
        await service.setEnabled(true)
        await settle()
        assert(center.asks == 1 && center.pending.isEmpty)
        service.updateLibrary(userID: a, hasActiveReading: true)
        await settle()
        assert(service.scheduled && center.pending.count == 1)
        service.setTime(Calendar.current.date(from: DateComponents(hour: 9, minute: 15))!)
        await settle()
        assert(center.pending.count == 1)
        assert(center.pending[id]?.trigger.dateMatching.hour == 9)
        assert(center.pending[id]?.trigger.dateMatching.minute == 15)
        assert(center.pending[id]?.trigger.repeats == true)
        service.updateLibrary(userID: a, hasActiveReading: false)
        await settle()
        assert(center.pending.isEmpty)
        service.updateLibrary(userID: a, hasActiveReading: true)
        await settle()
        await service.setEnabled(false)
        await settle()
        assert(center.pending.isEmpty)
        await service.setEnabled(true)
        await settle()
        center.status = .denied
        service.reconcile()
        await settle()
        assert(center.pending.isEmpty && !service.scheduled)
        center.status = .authorized
        service.reconcile()
        await settle()
        assert(center.pending.count == 1)
        let restored = ReadingReminderService(defaults: defaults, center: center)
        restored.setUser(a)
        await settle()
        assert(restored.enabled && restored.hour == 9 && restored.hasActiveReading)
        service.setUser(b)
        service.updateLibrary(userID: a, hasActiveReading: true)
        await settle()
        assert(!service.enabled && !service.hasActiveReading && center.pending.isEmpty)
        service.setUser(a)
        await settle()
        assert(service.enabled && service.hour == 9 && center.pending.count == 1)
        center.failAdd = true
        service.reconcile()
        await settle()
        assert(service.errorMessage != nil && !service.scheduled)
        center.failAdd = false
        center.pauseAdd = true
        service.reconcile()
        await settle()
        assert(center.suspended != nil)
        service.setUser(nil)
        center.pauseAdd = false
        center.suspended?.resume()
        await settle()
        assert(center.pending.isEmpty && !service.scheduled)
        center.pending[id] = UNNotificationRequest(
            identifier: id, content: UNMutableNotificationContent(),
            trigger: UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: 20), repeats: true)
        )
        let signedOutLaunch = ReadingReminderService(defaults: defaults, center: center)
        signedOutLaunch.setUser(nil)
        await settle()
        assert(center.pending.isEmpty)
        // Deterministic calendar tests, independent of the execution date.
        var clock = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 10))!
        var remoteDate: Date? = nil
        var fetchFails = false
        let inactiveCenter = UNUserNotificationCenter()
        inactiveCenter.status = .authorized
        let inactive = ReadingReminderService(defaults: defaults, center: inactiveCenter, now: { clock }, fetchActivity: {
            if fetchFails { throw URLError(.notConnectedToInternet) }
            return remoteDate
        })
        let account = UUID()
        let inactivityID = ReadingReminderService.inactivityRequestID
        inactive.setUser(account)
        await settle()
        assert(inactiveCenter.pending.isEmpty)
        fetchFails = true
        await inactive.setEnabled(true, inactivity: true)
        await settle()
        assert(inactive.activityError != nil && inactiveCenter.pending.isEmpty)
        fetchFails = false
        await inactive.refreshActivity()
        await settle()
        let initialTarget = inactive.inactivityScheduledDate!
        assert(Calendar.current.component(.day, from: initialTarget) == 12)
        assert(inactiveCenter.pending[inactivityID]?.trigger.repeats == false)
        assert(inactiveCenter.pending[ReadingReminderService.requestID] == nil)
        clock = clock.addingTimeInterval(86400)
        inactive.reconcile()
        await settle()
        assert(inactive.inactivityScheduledDate == initialTarget) // opening does not postpone
        inactive.recordActivity(userID: account, at: clock)
        await settle()
        assert(Calendar.current.component(.day, from: inactive.inactivityScheduledDate!) == 13)
        inactive.setInactivityDays(7)
        await settle()
        assert(Calendar.current.component(.day, from: inactive.inactivityScheduledDate!) == 17)
        inactive.recordActivity(userID: UUID(), at: clock.addingTimeInterval(10))
        assert(inactive.lastReadingActivity == clock)
        // Stale server results cannot undo a successful local reading action.
        remoteDate = clock.addingTimeInterval(-86400)
        await inactive.refreshActivity()
        await settle()
        assert(inactive.lastReadingActivity == clock)
        inactiveCenter.status = .denied
        inactive.reconcile()
        await settle()
        assert(inactiveCenter.pending.isEmpty)
        inactiveCenter.status = .authorized
        inactive.reconcile()
        await settle()
        assert(inactiveCenter.pending.count == 1)
        let target = inactive.inactivityScheduledDate!
        clock = target.addingTimeInterval(60)
        inactive.reconcile()
        await settle()
        assert(inactiveCenter.pending.isEmpty && inactive.inactivityScheduledDate == nil)
        let relaunched = ReadingReminderService(defaults: defaults, center: inactiveCenter, now: { clock }, fetchActivity: { remoteDate })
        relaunched.setUser(account)
        await relaunched.refreshActivity()
        await settle()
        assert(inactiveCenter.pending.isEmpty) // one notice per inactive period, even after relaunch
        await inactive.setEnabled(false, inactivity: true)
        await settle()
        assert(inactiveCenter.pending.isEmpty)
        await inactive.setEnabled(true, inactivity: true)
        await settle()
        assert(inactive.inactivityScheduledDate! > clock) // overdue opt-in uses next chosen time
        inactive.setUser(nil)
        await settle()
        assert(inactiveCenter.pending.isEmpty)
        print("PASS: inactivity opt-in, no history, failed fetch, 3/7 days, local activity, stale fetch, permissions, one-shot persistence, overdue and cancellation")
        print("PASS: opt-in, permissions, daily time, last-book removal, disable, account isolation, persistence, failure and logout during scheduling")
    }
}
'''
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp)
    (path / 'Checks.swift').write_text(stubs + source + checks)
    subprocess.run(['swiftc', '-parse-as-library', str(path / 'Checks.swift'), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
