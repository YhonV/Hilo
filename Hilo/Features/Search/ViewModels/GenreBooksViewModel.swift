//
//  GenreBooksViewModel.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//

import Foundation
import Observation

@Observable
@MainActor
final class GenreBooksViewModel {

    var books: [Book] = []
    var isLoading = false
    var errorMessage: String?

    private var currentOffset = 0
    private let pageSize = 20
    private(set) var hasMoreBooks = true

    func loadBooks(for genre: BookGenre) async {
        guard !isLoading, hasMoreBooks else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedBooks = try await OpenLibraryService.shared.searchBooks(
                query: "subject:\"\(genre.searchTerm)\"",
                offset: currentOffset
            )

            try Task.checkCancellation()

            let existingIds = Set(books.map(\.externalId))

            books.append(contentsOf: fetchedBooks.filter {
                !existingIds.contains($0.externalId)
            })

            currentOffset += pageSize
            hasMoreBooks = fetchedBooks.count == pageSize

        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            errorMessage = String(localized: "books_load_error_message")
        }
    }
}

