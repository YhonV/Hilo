//
//  CalendarActivityRow.swift
//  Hilo
//
//  Created by Cactu on 17-10-26.
//
import SwiftUI

struct CalendarActivityRow: View {

    let activity: CalendarActivity

    var body: some View {

        HStack(spacing: 12) {

            bookCover

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(activity.book.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(activityTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(activity.activityContent)
                    .font(.subheadline)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var bookCover: some View {

        if
            let cover = activity.book.cover,
            let url = URL(string: cover)
        {

            AsyncImage(url: url) { image in

                image
                    .resizable()
                    .scaledToFill()

            } placeholder: {

                Rectangle()
                    .fill(.quaternary)
            }
            .frame(width: 42, height: 62)
            .clipShape(
                RoundedRectangle(cornerRadius: 4)
            )

        } else {

            Rectangle()
                .fill(.quaternary)
                .frame(width: 42, height: 62)
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )
        }
    }

    private var activityTitle: String {

        switch activity.activityType {

        case .started:
            return String(localized: "activity_started")

        case .progress:
            return String(localized: "activity_progress")

        case .finished:
            return String(localized: "activity_finished")

        case .quote:
            return String(localized: "activity_quote")
        }
    }
}
