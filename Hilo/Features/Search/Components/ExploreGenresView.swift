//
//  ExploreGenresView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import SwiftUI

struct ExploreGenresView: View {
    let onGenreSelected: (BookGenre) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Text("search_explore_genres")
                    .font(.headline)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BookGenre.allCases, id: \.self) { genre in
                    Button {
                        onGenreSelected(genre)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: genre.icon)
                                .font(.subheadline)
                                .foregroundStyle(genre.color)

                            Text(genre.localizedName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(AppColors.primaryStrong)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .glassEffect(
                            .regular.tint(genre.color.opacity(0.12)).interactive(),
                            in: .capsule
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

