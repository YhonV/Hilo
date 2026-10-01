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
                    image.resizable().scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(Color.gray)
                        .padding(30)
                case .empty:
                    ProgressView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 110, height: 160)
            .clipped()
            .cornerRadius(10)
            
            Text(book.title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 20, alignment: .top)
            
            Text(book.authors.first ?? "")
                .font(.subheadline)
                .lineLimit(1)
            
        }
    }
}
