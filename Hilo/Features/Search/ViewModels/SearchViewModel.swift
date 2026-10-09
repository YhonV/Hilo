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

        do {
            let fetchedBooks = try await OpenLibraryService.shared.searchBooks(query: query)

            let enrichedBooks = try await enrichFirstBooks(fetchedBooks, query: query)

            try Task.checkCancellation()

            books = enrichedBooks

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

            enrichedBooks[index] =
                try await OpenLibraryService.shared.enrichBookWithBestEdition(
                    book: books[index],
                    query: query
                )
        }

        return enrichedBooks
    }
}
