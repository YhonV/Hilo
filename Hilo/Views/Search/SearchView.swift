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
    
    var body: some View {
        NavigationStack {
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
            .searchable(text: $searchText)
            .navigationTitle("hilo")
        }
    }
}

#Preview {
    SearchView()
}
