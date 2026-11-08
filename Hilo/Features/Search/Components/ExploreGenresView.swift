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
                        GenrePill(genre: genre, fillsWidth: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }
}

