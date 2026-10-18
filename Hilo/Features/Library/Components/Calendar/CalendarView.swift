
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

        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad de lectura")
                .font(.headline)

            calendarHeader
            weekDaysHeader
            calendarGrid
        }
        .padding(16)
        .glassEffect(
            .regular,
            in: .rect(cornerRadius: 24)
        )
        .padding(.horizontal, 4)
        .task {
            await viewModel.loadMonth()
        }
        .sheet(item: $selectedDay) { day in
            CalendarDayDetailSheet(
                date: day.date,
                activities: viewModel.activities(on: day.date)
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(320), .large])
        }
    }

    // MARK: - Encabezado

    private var calendarHeader: some View {

        HStack {

            Button {
                Task {
                    await viewModel.changeMonth(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular, in: .circle)

            Spacer()

            Text(viewModel.monthTitle)
                .font(.headline)
                .contentTransition(.numericText())

            Spacer()

            Button {
                Task {
                    await viewModel.changeMonth(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .frame(width: 36, height: 36)
            }
            .glassEffect(.regular, in: .circle)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Días de la semana

    private var weekDaysHeader: some View {

        LazyVGrid(columns: columns, spacing: 8) {

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

        LazyVGrid(columns: columns, spacing: 8) {

            ForEach(
                Array(viewModel.monthDays.enumerated()),
                id: \.offset
            ) { item in

                if let date = item.element {

                    CalendarDayCell(
                        date: date,
                        books: viewModel.books(on: date)
                    ) {
                        selectedDay = SelectedCalendarDay(date: date)
                    }

                } else {

                    Color.clear
                        .frame(height: 62)
                }
            }
        }
        .animation(.smooth(duration: 0.25), value: viewModel.displayedMonth)
    }
}

// MARK: - Día seleccionado

private struct SelectedCalendarDay: Identifiable {

    let date: Date

    var id: Date {
        date
    }
}
