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
    var isSaved: Bool = false
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 6) {

                AsyncImage(url: edition.displayCoverURL) { image in
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

                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, AppColors.accent)
                            .padding(5)
                    }
                }

                Text(edition.languageLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(edition.publisherLabel)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)

                Text(edition.publicationYear ?? String(localized: "book_unknown_year"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)

                if isSaved {
                    Label(String(localized: "edition_saved"), systemImage: "bookmark.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(width: 105, alignment: .leading)
            .padding(8)
            .background(isSelected ? .white.opacity(0.12) : .clear,
                        in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: String(localized: "edition_accessibility_description"),
                                   edition.languageLabel, edition.publisherLabel,
                                   edition.publicationYear ?? String(localized: "book_unknown_year")))
        .accessibilityValue(isSelected ? String(localized: "edition_selected") : (isSaved ? String(localized: "edition_saved") : ""))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

