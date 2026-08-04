//
//  SearchView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct SearchView: View {
    @State private var books: [Book] = []
    @State private var searchText: String = ""
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 26) {
                        ForEach(books.indices, id: \.self) { index in
                            BookCard(book: books[index])
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        Text("Calificación")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        Text("Géneros populares")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                }
                .searchable(text: $searchText)
                .task {
                    if let fetchBooks = try? await GoogleBooksService.shared.searchBook(query: "Harry Potter y la orden del fenix") {
                        books = fetchBooks
                        }
                    }
                }
            }
        }
}

#Preview {
    SearchView()
}
