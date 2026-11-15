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
    @Published var isExpanded = true

    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: CalendarService
    private let calendar: Calendar

    // Fecha que determina la semana visible
    private var referenceDate: Date

    init(service: CalendarService? = nil) {

        self.service = service ?? CalendarService.shared

        let calendar = Calendar.autoupdatingCurrent
        self.calendar = calendar

        let today = Date()

        self.referenceDate = today
        self.displayedMonth = calendar.dateInterval(
            of: .month,
            for: today
        )?.start ?? today

        self.selectedDate = today
    }

    // MARK: - Cargar actividades

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

        await loadActivities(
            startDate: interval.start,
            endDate: endDate
        )
    }

    private func loadWeek() async {

        guard let interval = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
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

        await loadActivities(
            startDate: interval.start,
            endDate: endDate
        )
    }

    private func loadActivities(
        startDate: Date,
        endDate: Date
    ) async {

        isLoading = true
        errorMessage = nil

        do {
            activities = try await service.getCalendarActivities(
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Navegación

    func navigate(by value: Int) async {

        if isExpanded {
            await changeMonth(by: value)
        } else {
            await changeWeek(by: value)
        }
    }

    func changeMonth(by value: Int) async {

        guard let newMonth = calendar.date(
            byAdding: .month,
            value: value,
            to: displayedMonth
        ) else {
            return
        }

        displayedMonth = newMonth
        referenceDate = newMonth
        selectedDate = nil

        await loadMonth()
    }

    func changeWeek(by value: Int) async {

        guard let newDate = calendar.date(
            byAdding: .weekOfYear,
            value: value,
            to: referenceDate
        ) else {
            return
        }

        referenceDate = newDate
        displayedMonth = calendar.dateInterval(
            of: .month,
            for: newDate
        )?.start ?? newDate

        selectedDate = nil

        await loadWeek()
    }

    // MARK: - Expandir / contraer

    func toggleExpanded() async {

        isExpanded.toggle()

        if isExpanded {
            await loadMonth()
        } else {
            await loadWeek()
        }
    }

    // MARK: - Volver a hoy

    func goToToday() async {

        let today = Date()

        referenceDate = today
        selectedDate = today

        displayedMonth = calendar.dateInterval(
            of: .month,
            for: today
        )?.start ?? today

        if isExpanded {
            await loadMonth()
        } else {
            await loadWeek()
        }
    }

    // MARK: - Días del mes

    var monthDays: [Date?] {

        guard let interval = calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ),
        let dayRange = calendar.range(
            of: .day,
            in: .month,
            for: displayedMonth
        ) else {
            return []
        }

        let firstDay = interval.start

        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )

        let leadingDays =
            (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(
            repeating: nil,
            count: leadingDays
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

    // MARK: - Días de la semana

    var weekDays: [Date?] {

        guard let interval = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
        ) else {
            return []
        }

        return (0..<7).map { offset in
            calendar.date(
                byAdding: .day,
                value: offset,
                to: interval.start
            )
        }
    }

    // MARK: - Días visibles

    var visibleDays: [Date?] {
        isExpanded ? monthDays : weekDays
    }

    // MARK: - Actividades

    func activities(on date: Date) -> [CalendarActivity] {

        activities.filter {
            calendar.isDate(
                $0.date,
                inSameDayAs: date
            )
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

    // MARK: - Libros únicos

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

    // MARK: - Textos

    var monthTitle: String {

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")

        let date = isExpanded ? displayedMonth : referenceDate

        return formatter
            .string(from: date)
            .capitalized
    }

    func dayTitle(_ date: Date) -> String {

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.dateStyle = .full

        return formatter
            .string(from: date)
            .capitalized
    }
}
