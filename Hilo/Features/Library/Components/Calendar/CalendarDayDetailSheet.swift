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
                            "Sin actividad",
                            systemImage: "book.closed",
                            description: Text(
                                "No registraste actividades de lectura este día."
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
            .navigationTitle("Actividad de lectura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

