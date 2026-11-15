//
//  DiscoveryBooksSectionView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import SwiftUI

struct DiscoveryBooksSectionView: View {
    let books: [Book]
    let isLoading: Bool
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Text("search_discover_books")
                    .font(.headline)

                Spacer()

                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryStrong)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .opacity(isLoading ? 0.5 : 1)
                .accessibilityLabel(Text("search_discover_refresh"))
            }
            .padding(.horizontal)


            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(books, id: \.externalId) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                BookCoverView(
                                    url: book.cover,
                                    width: 115,
                                    height: 165
                                )

                                Text(book.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(AppColors.primaryStrong)
                                    .lineLimit(2)

                                Text(book.authors.joined(separator: ", "))
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

