//
//  BookDetailView.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

struct BookDetailView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack {
                    AsyncImage(url: URL(string: book.cover)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 260)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(30)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    
                    Text(book.title)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if let rating = book.averageRating {
                            Label(
                                String(format: "%.1f", rating),
                                systemImage: "star.fill"
                            )
                        }
                        
                        if book.numberOfPages > 0 {
                            Label(
                                "\(book.numberOfPages) páginas",
                                systemImage: "book.pages"
                            )
                        }
                        
                        if let publishedDate = book.publishedDate {
                            Label(
                                publishedDate,
                                systemImage: "calendar"
                            )
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    if !book.genre.isEmpty {
                        Text(book.genre.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                                        
                    Button {
                        
                    } label: {
                        Label("Add to my list", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sinopsis")
                            .font(.title2.bold())
                        
                        Text(book.description ?? "no-description")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                .navigationTitle(book.title)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
