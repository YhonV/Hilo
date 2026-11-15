"""Verify weekly page calculations and scheduling using the notification-center double."""
import ast
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
tree = ast.parse((root / 'Tests/check_reading_reminders.py').read_text())
stubs = next(ast.literal_eval(node.value) for node in tree.body
             if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'stubs' for t in node.targets))
source = (root / 'Hilo/Models/WeeklyReadingGoal.swift').read_text()
source += (root / 'Hilo/Services/WeeklyGoalReminderService.swift').read_text().replace('import UserNotifications', '')
checks = r'''
@main struct Checks {
    @MainActor static func settle() async { try? await Task.sleep(for: .milliseconds(30)) }
    @MainActor static func main() async {
        let calendar = WeeklyReadingGoal.calendar
        var clock = calendar.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 10))!
        let monday = WeeklyReadingGoal.start(of: clock)
        assert(calendar.component(.weekday, from: monday) == 2)
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        assert(WeeklyReadingGoal.start(of: sunday) == monday)
        let nextMonday = calendar.date(byAdding: .day, value: 7, to: monday)!
        assert(WeeklyReadingGoal.start(of: nextMonday) != monday)
        let yearBoundary = calendar.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        assert(calendar.component(.year, from: WeeklyReadingGoal.start(of: yearBoundary)) == 2026)
        let goal = WeeklyReadingGoal(targetPages: 100, pagesRead: 43, weekStart: monday)
        assert(goal.remainingPages == 57 && goal.fraction == 0.43)
        assert(goal.checkpoints(after: clock, hour: 20, minute: 0).map(\.day) == [6])
        assert(goal.checkpoints(after: nextMonday, hour: 20, minute: 0).isEmpty)
        let complete = WeeklyReadingGoal(targetPages: 100, pagesRead: 120, weekStart: monday)
        assert(complete.fraction == 1 && complete.remainingPages == 0 && complete.isComplete)

        let suite = "WeeklyTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let center = UNUserNotificationCenter()
        center.status = .authorized
        var pages = 0
        var fails = false
        let service = WeeklyGoalReminderService(defaults: defaults, center: center, now: { clock }, fetchPages: { start, end in
            assert(end > start)
            if fails { throw URLError(.notConnectedToInternet) }
            return pages
        })
        let user = UUID()
        service.setUser(user)
        await service.refresh()
        await settle()
        assert(center.pending.isEmpty && !service.enabled)
        await service.setEnabled(true)
        await settle()
        assert(center.pending.count == 2)
        assert(center.pending.values.allSatisfy { !$0.trigger.repeats })
        pages = 43
        await service.refresh()
        await settle()
        assert(center.pending.count == 1 && center.pending["hilo.reading.weekly.6"] != nil)
        pages = 100
        await service.refresh()
        await settle()
        assert(center.pending.isEmpty && service.progress!.isComplete)
        service.setTarget(200)
        await settle()
        assert(center.pending.count == 1)
        service.setTarget(50)
        await settle()
        assert(center.pending.isEmpty)
        service.setTarget(100)
        pages = 0
        fails = true
        await service.refresh()
        await settle()
        assert(center.pending.isEmpty && service.errorMessage != nil && service.progress == nil)
        fails = false
        await service.refresh()
        await settle()
        assert(center.pending.count == 2)
        center.status = .denied
        service.reconcile()
        await settle()
        assert(center.pending.isEmpty)
        center.status = .authorized
        service.setTime(hour: 19, minute: 15)
        await settle()
        assert(center.pending.count == 2)
        assert(center.pending.values.allSatisfy { $0.trigger.dateMatching.hour == 19 && $0.trigger.dateMatching.minute == 15 })
        clock = sunday.addingTimeInterval(21 * 3600)
        service.reconcile()
        await settle()
        assert(center.pending.isEmpty) // no repeat after the checkpoints
        clock = nextMonday.addingTimeInterval(10 * 3600)
        service.reconcile()
        await settle()
        assert(center.pending.isEmpty) // never use last week's total
        await service.refresh()
        await settle()
        assert(center.pending.count == 2)
        await service.setEnabled(false)
        await settle()
        assert(center.pending.isEmpty)
        await service.setEnabled(true)
        await settle()
        center.pauseAdd = true
        service.reconcile()
        await settle()
        service.setUser(nil)
        center.pauseAdd = false
        center.suspended?.resume()
        await settle()
        assert(center.pending.isEmpty)
        service.setUser(UUID())
        assert(!service.enabled && service.targetPages == 100 && service.progress == nil)
        service.setUser(user)
        assert(service.enabled && service.targetPages == 100)
        print("PASS: Monday/Sunday/year boundaries, proportional progress, completion, target/time updates, errors, permissions, rollover, isolation and cancellation during add")
    }
}
'''
with tempfile.TemporaryDirectory() as tmp:
    path = Path(tmp)
    (path / 'Checks.swift').write_text(stubs + source + checks)
    subprocess.run(['swiftc', '-parse-as-library', str(path / 'Checks.swift'), '-o', str(path / 'checks')], check=True)
    subprocess.run([str(path / 'checks')], check=True)
