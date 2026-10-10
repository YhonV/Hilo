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
    private var initialBooks: [Book] = []
    private var lastSearchQuery: String?
    
    // MARK: - Función cargar libros iniciales (Luego será mejorada, enviando generos favoritos del usuario)
    func loadInitialBooks() async throws {
        guard !hasLoadedInitialBooks else { return }

        let query = "Harry Potter"

        let fetchedBooks = try await OpenLibraryService.shared.searchBooks(query: query)

        books = try await enrichFirstBooks(fetchedBooks, query: query)

        hasLoadedInitialBooks = true
    }
    
    // MARK: - Función de buscar libros
    func searchBooks() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard query != lastSearchQuery else { return }

        do {
            let fetchedBooks = try await OpenLibraryService.shared.searchBooks(query: query)

            let sortedBooks = fetchedBooks.sorted { firstBook, secondBook in

                let firstScore = titleMatchScore(title: firstBook.title, query: query)

                let secondScore = titleMatchScore(title: secondBook.title, query: query)

                return firstScore > secondScore
            }

            let enrichedBooks = try await enrichFirstBooks(
                sortedBooks,
                query: query
            )
            
            try Task.checkCancellation()

            books = enrichedBooks
            lastSearchQuery = query

        } catch is CancellationError {
            return

        } catch {
            print("Error cargando libros: \(error)")
        }
    }
    
    func restoreInitialBooks() {
        books = initialBooks
    }
    
    private func enrichFirstBooks(_ books: [Book], query: String) async throws -> [Book] {

        var enrichedBooks = books

        let amount = min(3, books.count)

        for index in 0..<amount {

            try Task.checkCancellation()

            let originalBook = books[index]

            let enrichedBook =
                try await OpenLibraryService.shared.enrichBookWithBestEdition(
                    book: originalBook,
                    query: query
                )

            enrichedBooks[index] = enrichedBook
        }

        return enrichedBooks
    }
    
    private func titleMatchScore(title: String, query: String) -> Int {

        let normalizedTitle = title.lowercased()
        let normalizedQuery = query.lowercased()

        if normalizedTitle == normalizedQuery {
            return 100
        }

        if normalizedTitle.hasPrefix(normalizedQuery) {
            return 80
        }

        if normalizedTitle.contains(normalizedQuery) {
            return 60
        }

        return 0
    }
}
