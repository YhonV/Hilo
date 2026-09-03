//
//  LibraryService.swift
//  Hilo
//
//  Created by Cactu on 29-08-26.
//
import Foundation
import Supabase

struct EditionResponse: Decodable {
    let editionId: UUID

    enum CodingKeys: String, CodingKey {
        case editionId = "edition_id"
    }
}

struct UserBookResponse: Decodable {
    let statusId: Int

    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
    }
}

final class LibraryService {
    static let shared = LibraryService()
    private init() {}

    func saveBookToLibrary(book: Book, status: BookStatus) async throws {

        let params = SaveBookParams(
            p_google_books_id: book.googleBookId,
            p_title: book.title,
            p_status: status.rawValue,
            p_description: book.description,
            p_authors: book.authors,
            p_genres: book.genre,
            p_isbn: book.isbn,
            p_publisher: book.editorial,
            p_language: book.language,
            p_published_date: book.publishedDate,
            p_number_of_pages: book.numberOfPages,
            p_cover_url: book.cover
        )

        try await supabase
            .rpc("save_book_to_library", params: params)
            .execute()
    }
    
    func getBookStatusFromUserLibrary(book: Book,userId: UUID) async throws -> BookStatus? {

        var editionQuery = supabase
            .from("book_editions")
            .select("edition_id")

        if !book.googleBookId.isEmpty {
            editionQuery = editionQuery
                .eq("google_books_id", value: book.googleBookId)
        } else if let isbn = book.isbn {
            editionQuery = editionQuery
                .eq("isbn", value: isbn)
        } else {
            return nil
        }

        let editions: [EditionResponse] = try await editionQuery
            .limit(1)
            .execute()
            .value

        guard let edition = editions.first else {
            print("No se encontró la edición")
            return nil
        }

        let userBooks: [UserBookResponse] = try await supabase
            .from("user_book")
            .select("status_id")
            .eq("user_id", value: userId.uuidString)
            .eq("edition_id", value: edition.editionId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let userBook = userBooks.first else {
            print("El usuario no tiene esta edición")
            return nil
        }

        let status = mapBookStatus(statusId: userBook.statusId)

        return status
    }
    
    private func mapBookStatus(statusId: Int) -> BookStatus? {
        switch statusId {
        case 1:
            return .reading
        case 2:
            return .read
        case 3:
            return .toRead
        default:
            return nil
        }
    }
}
