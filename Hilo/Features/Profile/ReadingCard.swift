//
//  ReadingCard.swift
//  Hilo
//
//  Created by Cactu on 05-09-26.
//

import SwiftUI

struct ReadingCard: View {

    let readingBook: CurrentlyReadingBook

    private var progress: Double {
        guard let totalPages = readingBook.edition?.numberOfPages,
              totalPages > 0 else {
            return 0
        }

        let value = Double(readingBook.currentPage) / Double(totalPages)

        return min(max(value, 0), 1)
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var authors: String {
        readingBook.book.authors
            .map(\.name)
            .joined(separator: ", ")
    }

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            AsyncImage(
                url: URL(string: readingBook.edition?.coverURL ?? "")
            ) { phase in

                switch phase {

                case .empty:
                    ProgressView()

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    Image(systemName: "book.closed")
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .foregroundStyle(AppColors.secondaryText)

                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 90, height: 130)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: 8) {

                Text(readingBook.book.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(authors)
                    .font(.callout)
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)

                if let totalPages = readingBook.edition?.numberOfPages,
                   totalPages > 0 {

                    Text("\(progressPercentage)% leído")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    ProgressView(value: progress)
                        .tint(AppColors.accent)

                    Text(
                        "Página \(readingBook.currentPage) de \(totalPages)"
                    )
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)

                } else {

                    Text("Página \(readingBook.currentPage)")
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 320)
    }
}
