//
//  LibraryViewModel.swift
//  Hilo
//
//  Created by Cactu on 18-09-26.
//
import SwiftUI

@MainActor
@Observable
final class LibraryViewModel {
    // MARK: - Servicios
    private let libraryService = LibraryService()
    
    // MARK: - Objetos
    var userBooks: [UserLibraryBook] = []
    
    // MARK: - Obtener los libros del usuario
    func getUserBooks(userId: UUID) async throws {
        userBooks = try await libraryService.getUsersBook(userId: userId)
    }
    
    // MARK: - Actualizar progreso de lectura
    func updateBookProgres(userBookId: UUID,currentPage: Int) async throws {
        try await libraryService.updateBookProgress(userBookId: userBookId, currentPage: currentPage)
        if let index = userBooks.firstIndex(
            where: { $0.userBookId == userBookId }
        ) {
            userBooks[index].currentPage = currentPage
        }
    }
    
    // MARK: - Actualizar libro de leído a leyendo
    func restartReading(userBookId: UUID) async throws {

        let updatedBook = try await libraryService.restartReading(userBookId: userBookId)

        if let index = userBooks.firstIndex(
            where: { $0.userBookId == userBookId }
        ) {
            userBooks[index].statusId = updatedBook.statusId
            userBooks[index].status = LibraryStatus(
                name: statusName(from: updatedBook.statusId)
            )
            userBooks[index].currentPage = updatedBook.currentPage
            userBooks[index].startedAt = updatedBook.startedAt
            userBooks[index].finishedAt = updatedBook.finishedAt
        }
    }
    
    // MARK: - Finalizar lectura

    func finishReading(userBookId: UUID) async throws {

        let updatedBook = try await libraryService.finishReading(
            userBookId: userBookId
        )

        if let index = userBooks.firstIndex(
            where: { $0.userBookId == userBookId }
        ) {
            userBooks[index].statusId = updatedBook.statusId

            userBooks[index].status = LibraryStatus(
                name: statusName(from: updatedBook.statusId)
            )

            userBooks[index].currentPage = updatedBook.currentPage
            userBooks[index].startedAt = updatedBook.startedAt
            userBooks[index].finishedAt = updatedBook.finishedAt
        }
    }
    
    private func statusName(from statusId: Int) -> String {
        switch statusId {
        case 1:
            return "reading"
        case 2:
            return "read"
        case 3:
            return "toRead"
        default:
            return ""
        }
    }
    
    func getUserBook(userBookId: UUID) async throws -> UserLibraryBook {

        let book = try await libraryService.getUserBook(
            userBookId: userBookId
        )

        if let index = userBooks.firstIndex(where: {
            $0.userBookId == book.userBookId
        }) {
            userBooks[index] = book
        } else {
            userBooks.append(book)
        }

        return book
    }
}
