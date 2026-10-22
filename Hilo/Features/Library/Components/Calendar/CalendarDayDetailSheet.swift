//
//  CalendarDayDetailSheet.swift
//  Hilo
//
//  Created by Cactu on 17-10-26.
//

import SwiftUI

struct CalendarDayDetailSheet: View {

    let date: Date
    let activities: [CalendarActivity]

    @Environment(\.dismiss) private var dismiss

    private var dateTitle: String {
        date.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 16) {

                    Text(dateTitle)
                        .font(.title3)
                        .fontWeight(.semibold)

                    if activities.isEmpty {

                        ContentUnavailableView(
                            String(localized: "calendar_no_activity"),
                            systemImage: "book.closed",
                            description: Text(
                                String(localized: "calendar_no_activity_description")
                            )
                        )

                    } else {
                        VStack(alignment: .leading, spacing: 12) {

                            ForEach(
                                Array(activities.enumerated()),
                                id: \.offset
                            ) { item in

                                CalendarTimelineRow(
                                    activity: item.element,
                                    isLast: item.offset == activities.count - 1
                                )
                            }
                        }

                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle(String(localized: "calendar_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common_close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

