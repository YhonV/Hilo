//
//  SearchViewModel.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

@Observable
class SearchViewModel {
    var books: [Book] = []
    var searchText: String = ""
    var hasLoadedInitialBooks: Bool = false
    
    func loadInitialBooks() async throws {

        guard !hasLoadedInitialBooks else { return }

        let fetchBooks = try await GoogleBooksService.shared.searchBook( query: "Harry Potter y la orden del fenix")

        books = fetchBooks
        hasLoadedInitialBooks = true
    }
    
    func searchBooks() async {

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return
        }

        do {
            let fetchBooks = try await GoogleBooksService.shared.searchBook(query: query)
            books = fetchBooks

        } catch {
            print("Error cargando libros: \(error)")
        }
        
        do {
            
        }
    }
    
}
