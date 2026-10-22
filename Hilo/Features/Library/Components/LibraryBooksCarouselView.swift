//
//  LibraryBooksCarouselView.swift
//  Hilo
//
//  Created by Cactu on 18-09-26.
//

import SwiftUI

struct LibraryBooksCarouselView: View {
    
    let userLibraryBooks: [UserLibraryBook]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
                ForEach(userLibraryBooks, id: \.bookId) { book in
                    let authors = book.book.bookAuthors
                        .map { $0.author.name }
                        .joined(separator: ", ")
                    NavigationLink {
                        LibraryBookDetailView(bookDetail: book)
                    } label: {
                        LazyHStack(alignment: .top, spacing: 12) {
                            // MARK: - Portada del libro
                            AsyncImage(
                                url: URL(string: book.edition.coverUrl ?? "")
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
                                Text(book.book.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .lineLimit(2, reservesSpace: true)
                                
                                Text(authors.isEmpty ? String(localized: "book_unknown_author") : authors)
                                    .font(.callout)
                                    .foregroundStyle(AppColors.secondaryText)
                                    .lineLimit(1)
                                
                                if let currentPage = book.currentPage,
                                   let totalPages = book.edition.numberOfPages, totalPages > 0 {
                                    
                                    let progress = min(Double(currentPage) / Double(totalPages),1.0)
                                    let progressPercentage = Int(progress * 100)
                                    
                                    Text(String(format: String(localized: "reading_progress_percentage"), progressPercentage))
                                        .font(.subheadline)
                                        .foregroundStyle(AppColors.secondaryText)
                                    
                                    ProgressView(value: progress)
                                        .tint(AppColors.accent)
                                    
                                    Text(String(format: String(localized: "reading_page_position"), currentPage, totalPages))
                                        .font(.footnote)
                                        .foregroundStyle(AppColors.secondaryText)
                                } else if let currentPage = book.currentPage {
                                    Text(String(format: String(localized: "reading_page_number"), currentPage))
                                        .font(.footnote)
                                        .foregroundStyle(AppColors.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(width: 320)
                    }
                }
            }
        }
    }
}
