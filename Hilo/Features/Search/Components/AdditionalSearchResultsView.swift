//
//  AdditionalSearchResultsView.swift
//  Hilo
//
//  Created by Cactu on 11-10-26.
//

import SwiftUI

struct AdditionalSearchResultsView: View {
    let books: [Book]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 10) {
                Image(systemName: "books.vertical")
                    .foregroundStyle(AppColors.primaryStrong)

                Text("Explorar más libros")
                    .font(.headline)
            }

            Button {
                withAnimation(.smooth(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("\(books.count) resultados adicionales")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(isExpanded ? "Ver menos" : "Ver todos")
                        .foregroundStyle(AppColors.primaryStrong)
                        .fontWeight(.semibold)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppColors.primaryStrong)
                }
                .font(.subheadline)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()

                LazyVStack(spacing: 0) {
                    ForEach(books, id: \.externalId) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookSearchResultRow(book: book)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppColors.primaryStrong.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}
