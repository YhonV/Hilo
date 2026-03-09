//
//  SearchView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct SearchView: View {
    @State private var books: [Book] = []
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Hola desde search")
                
                Button("Probar API") {
                    Task {
                        if let fetchBooks = try? await GoogleBooksService.shared.searchBook(query: "harry potter") {
                            books = fetchBooks
                        }
                    }
                }
                ForEach(books.indices, id: \.self) { index in
                    BookCard(book: books[index])
                }
            }
        }
    }
}
