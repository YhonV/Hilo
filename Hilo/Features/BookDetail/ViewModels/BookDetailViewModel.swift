//
//  BookDetail.swift
//  Hilo
//
//  Created by Cactu on 29-08-26.
//
import SwiftUI

@Observable
class BookDetailViewModel {
    var book: Book
    var bookStatus: BookStatus?
    
    init(book: Book) {
        self.book = book
    }
    
    private var libraryService = LibraryService.shared
    
    func getBooksFromUserLibrary(userId: UUID) async throws {
        bookStatus = try await libraryService.getBookStatusFromUserLibrary(book: book, userId: userId)
    }
    
    func saveBook(status: BookStatus) async throws {
        let previousStatus = bookStatus
        bookStatus = status
        do {
            try await libraryService.saveBookToLibrary(book: book, status: status)
        } catch {
            bookStatus = previousStatus
            throw error
        }
    }
    
}
