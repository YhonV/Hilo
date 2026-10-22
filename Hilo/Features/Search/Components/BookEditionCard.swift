//
//  BookEditionCard.swift
//  Hilo
//
//  Created by Cactu on 21-10-26.
//

import SwiftUI

struct BookEditionCard: View {

    let edition: OpenLibraryEditionDTO
    let isSelected: Bool
    let action: () -> Void

    private var coverURL: URL? {
        guard let coverId = edition.covers?.first else {
            return nil
        }

        return URL(
            string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
        )
    }

    var body: some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 6) {

                AsyncImage(url: coverURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.12))
                        .overlay {
                            Image(systemName: "book.closed")
                                .foregroundStyle(.white.opacity(0.7))
                        }
                }
                .frame(width: 85, height: 125)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? AppColors.accent : .clear,
                            lineWidth: 3
                        )
                }

                Text(edition.publishers?.first ?? "")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)

                Text(edition.publishDate ?? "")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(width: 90, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

