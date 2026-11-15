//
//  BookSearchResultRow.swift
//  Hilo
//
//  Created by Cactu on 13-09-26.
//

import SwiftUI

struct BookSearchResultRow: View {

    let book: Book

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            BookCoverView(
                url: book.cover,
                width: 85,
                height: 120
            )

            VStack(alignment: .leading, spacing: 4) {

                Text(book.title)
                    .foregroundStyle(AppColors.primaryStrong)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(book.authors.joined(separator: ", "))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(2)

                if let rating = book.averageRating {
                    HStack(spacing: 4) {

                        Image(systemName: "star.fill")

                        Text(String(format: "%.1f", rating))

                        if book.totalReviews > 0 {
                            Text("(\(book.totalReviews))")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }
}
