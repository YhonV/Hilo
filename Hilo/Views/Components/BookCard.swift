//
//  BookCard.swift
//  Hilo
//
//  Created by YhonGoogleBooksResponse Vivas on 08-03-26.
//
import SwiftUI

struct BookCard: View {
    let book: Book
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: book.cover)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .failure:
                    Image(systemName: "photo")
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 80, height: 120)
            Text(book.title)
                .font(.headline)
            
            Text(book.author)
                .font(.subheadline)
            
        }
    }
}
