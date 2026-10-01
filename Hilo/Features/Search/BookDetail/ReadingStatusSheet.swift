//
//  ReadingStatusSheet.swift
//  Hilo
//
//  Created by Cactu on 03-09-26.
//
import SwiftUI

struct ReadingStatusSheet: View {

    let currentStatus: BookStatus?
    let onSelect: (BookStatus) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 6) {

                Text("reading_status_title")
                    .font(.title2.bold())

                Text("reading_status_subtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {

                statusButton(
                    title: String(localized: "reading_status"),
                    icon: "book.fill",
                    status: .reading
                )
                
                Divider()

                statusButton(
                    title: String(localized:"toRead_status"),
                    icon: "bookmark.fill",
                    status: .toRead
                )

                Divider()

                statusButton(
                    title: String(localized:"read_status"),
                    icon: "checkmark.circle.fill",
                    status: .read
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func statusButton(
        title: String,
        icon: String,
        status: BookStatus
    ) -> some View {

        Button {

            onSelect(status)
            dismiss()

        } label: {

            HStack(spacing: 16) {

                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 28)

                Text(title)
                    .font(.headline)

                Spacer()

                if currentStatus == status {

                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(
                currentStatus == status
                    ? AppColors.accent
                    : AppColors.titles
            )
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }
}
