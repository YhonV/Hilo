//
//  CalendarViewModel.swift
//  Hilo
//
//  Created by Cactu on 17-10-26.
//
import Foundation
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {

    @Published private(set) var activities: [CalendarActivity] = []
    @Published var displayedMonth: Date
    @Published var selectedDate: Date?

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: CalendarService
    private let calendar: Calendar

    init(service: CalendarService? = nil) {
        self.service = service ?? CalendarService.shared

        var calendar = Calendar.autoupdatingCurrent
        calendar.locale = .autoupdatingCurrent
        calendar.timeZone = .current

        self.calendar = calendar

        let today = Date()

        self.displayedMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: today)
        ) ?? today

        self.selectedDate = today
    }

    // MARK: - Cargar mes

    func loadMonth() async {

        guard let interval = calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ) else {
            return
        }

        guard let endDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: interval.end
        ) else {
            return
        }

        isLoading = true
        errorMessage = nil

        do {

            activities = try await service.getCalendarActivities(
                startDate: interval.start,
                endDate: endDate
            )

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Navegación

    func changeMonth(by value: Int) async {

        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = newMonth
        selectedDate = nil

        await loadMonth()
    }

    // MARK: - Días del mes

    var monthDays: [Date?] {

        guard
            let monthInterval = calendar.dateInterval(
                of: .month,
                for: displayedMonth
            ),
            let dayRange = calendar.range(
                of: .day,
                in: .month,
                for: displayedMonth
            )
        else {
            return []
        }

        let firstDay = monthInterval.start

        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )

        let leadingEmptyDays =
            (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(
            repeating: nil,
            count: leadingEmptyDays
        )

        for offset in 0..<dayRange.count {

            if let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: firstDay
            ) {
                days.append(date)
            }
        }

        return days
    }

    // MARK: - Actividades

    func activities(on date: Date) -> [CalendarActivity] {

        activities.filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    func hasActivities(on date: Date) -> Bool {
        !activities(on: date).isEmpty
    }

    func isSelected(_ date: Date) -> Bool {

        guard let selectedDate else {
            return false
        }

        return calendar.isDate(
            selectedDate,
            inSameDayAs: date
        )
    }

    // MARK: - Textos

    var monthTitle: String {

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "LLLL yyyy"

        return formatter
            .string(from: displayedMonth)
            .capitalized
    }

    func dayTitle(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .full

        return formatter
            .string(from: date)
            .capitalized
    }
    
    // MARK: - Obtener libros únicos de un día
    func books(on date: Date) -> [CalendarBook] {

        let dayActivities = activities(on: date)

        var bookIds = Set<UUID>()

        return dayActivities.compactMap { activity in

            let book = activity.book

            guard bookIds.insert(book.bookId).inserted else {
                return nil
            }

            return book
        }
    }
}
