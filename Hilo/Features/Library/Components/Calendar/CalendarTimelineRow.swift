//
//  CalendarTimelineRow.swift
//  Hilo
//
//  Created by Cactu on 17-10-26.
//

import SwiftUI

struct CalendarTimelineRow: View {

    let activity: CalendarActivity
    let isLast: Bool

    private var activityIcon: String {
        switch activity.activityType {
        case .started:
            "book"
        case .progress:
            "book.pages"
        case .finished:
            "checkmark"
        case .quote:
            "quote.opening"
        }
    }

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            VStack(spacing: 0) {

                Image(systemName: activityIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 32, height: 32)
                    .background(
                        .quaternary,
                        in: Circle()
                    )

                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 6)
                }
            }

            CalendarActivityRow(activity: activity)
                .padding(.vertical, 6)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

