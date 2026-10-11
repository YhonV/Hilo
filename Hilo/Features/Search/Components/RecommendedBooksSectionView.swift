//
//  RecommendedBooksSectionView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct RecommendedBooksSectionView: View {
    let books: [Book]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text(title)
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(books, id: \.externalId) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: book.cover)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.primaryStrong.opacity(0.08))
                                }
                                .frame(width: 115, height: 165)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                Text(book.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .foregroundStyle(AppColors.primaryStrong)

                                Text(book.authors.first ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 115, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

