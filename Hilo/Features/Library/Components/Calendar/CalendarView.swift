

import SwiftUI

struct CalendarView: View {

    @StateObject private var viewModel: CalendarViewModel
    @State private var selectedDay: SelectedCalendarDay?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 7
    )

    private var weekDays: [String] {

        let calendar = Calendar.autoupdatingCurrent
        let symbols = calendar.veryShortStandaloneWeekdaySymbols

        return (0..<7).map { offset in
            let index = (calendar.firstWeekday - 1 + offset) % 7
            return symbols[index]
        }
    }

    init(service: CalendarService? = nil) {

        _viewModel = StateObject(
            wrappedValue: CalendarViewModel(service: service)
        )
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            calendarHeader

            weekDaysHeader

            calendarGrid
        }
        .padding(.vertical, 12)
        .animation(
            .smooth(duration: 0.35),
            value: viewModel.isExpanded
        )
        .task {
            await viewModel.loadMonth()
        }
        .sheet(item: $selectedDay) { day in

            CalendarDayDetailSheet(
                date: day.date,
                activities: viewModel.activities(on: day.date)
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([
                .height(320),
                .large
            ])
        }
    }

    // MARK: - Encabezado

    private var calendarHeader: some View {

        HStack(spacing: 12) {

            VStack(alignment: .leading, spacing: 4) {

                Text(String(localized: "calendar_title"))
                    .font(.headline)

                Text(viewModel.monthTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            Spacer()

            HStack(spacing: 4) {

                // Mes o semana anterior
                Button {
                    Task {
                        await viewModel.navigate(by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 36)
                }

                // Mes o semana siguiente
                Button {
                    Task {
                        await viewModel.navigate(by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 36)
                }

                // Expandir / contraer
                Button {
                    Task {
                        await viewModel.toggleExpanded()
                    }
                } label: {
                    Image(
                        systemName: viewModel.isExpanded
                            ? "chevron.up"
                            : "chevron.down"
                    )
                    .frame(width: 32, height: 36)
                    .contentTransition(.symbolEffect(.replace))
                }
                .accessibilityLabel(
                    viewModel.isExpanded
                        ? String(localized: "calendar_collapse")
                        : String(localized: "calendar_expand")
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            .glassEffect(.regular, in: .capsule)
            .disabled(viewModel.isLoading)
        }
        .sensoryFeedback(
            .selection,
            trigger: viewModel.isExpanded
        )
    }

    // MARK: - Encabezado de semana

    private var weekDaysHeader: some View {

        LazyVGrid(
            columns: columns,
            spacing: 6
        ) {

            ForEach(0..<7, id: \.self) { index in

                Text(weekDays[index])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendario

    private var calendarGrid: some View {

        LazyVGrid(
            columns: columns,
            spacing: 8
        ) {

            ForEach(
                Array(viewModel.visibleDays.enumerated()),
                id: \.offset
            ) { item in

                if let date = item.element {

                    CalendarDayCell(
                        date: date,
                        books: viewModel.books(on: date),
                        activityCount: viewModel.activities(on: date).count
                    ) {
                        selectedDay = SelectedCalendarDay(date: date)
                    }

                } else {

                    Color.clear
                        .frame(height: 58)
                }
            }
        }
    }
}

// MARK: - Día seleccionado

private struct SelectedCalendarDay: Identifiable {

    let date: Date

    var id: Date {
        date
    }
}
