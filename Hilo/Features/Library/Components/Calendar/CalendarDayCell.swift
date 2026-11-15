//
//  CalendarDayCell.swift
//  Hilo
//
//  Created by Cactu on 17-10-26.
//
import SwiftUI

struct CalendarDayCell: View {

    let date: Date
    let books: [CalendarBook]
    let activityCount: Int
    let action: () -> Void
    private var isToday: Bool {
        Calendar.autoupdatingCurrent.isDateInToday(date)
    }

    private var dayNumber: Int {
        Calendar.autoupdatingCurrent.component(.day, from: date)
    }
    @State private var tapCount = 0


    var body: some View {

        Button {
            tapCount += 1
            action()
        } label: {

            VStack(spacing: 4) {

                Text(dayNumber.formatted())
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .medium)
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 24, height: 24)
                    .background {
                        if isToday {
                            Circle()
                                .fill(Color.accentColor)
                        }
                    }
                if let book = books.first {

                    CachedBookImage(url: URL(string: book.cover ?? "")) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(.quaternary)
                            .overlay {
                                Image(systemName: "book.closed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                    }
                    .frame(width: 28, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(alignment: .bottomTrailing) {
                        if activityCount > 1 {
                            Text("+\(activityCount - 1)")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 3)
                                .background(
                                    AppColors.primary.opacity(0.85),
                                    in: Capsule()
                                )
                                .offset(x: 5, y: 3)
                        }
                    }

                } else {

                    Color.clear
                        .frame(width: 28, height: 38)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(CalendarDayButtonStyle())
        .sensoryFeedback(.selection, trigger: tapCount)
    }
}

/// Native button press feedback leaves vertical drags to the parent ScrollView.
private struct CalendarDayButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
