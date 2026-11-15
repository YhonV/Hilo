import Foundation

/// Calendar weeks always run Monday through Sunday in the device's local time zone.
struct WeeklyReadingGoal {
    let targetPages: Int
    let pagesRead: Int
    let weekStart: Date

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    static func start(of date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }

    var remainingPages: Int { max(0, targetPages - pagesRead) }
    var fraction: Double { min(1, Double(max(0, pagesRead)) / Double(max(1, targetPages))) }
    var isComplete: Bool { pagesRead >= targetPages }

    /// Only this week's future checkpoints are scheduled, never repeating requests.
    func checkpoints(after now: Date, hour: Int, minute: Int) -> [(day: Int, date: Date)] {
        guard targetPages > 0, !isComplete, Self.start(of: now) == weekStart else { return [] }
        return [3, 6].compactMap { day in
            let expected = Int(ceil(Double(targetPages) * Double(day) / 7))
            guard pagesRead < expected,
                  let date = Self.calendar.date(byAdding: .day, value: day - 1, to: weekStart),
                  let time = Self.calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date),
                  time > now else { return nil }
            return (day, time)
        }
    }
}
