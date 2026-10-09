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

struct LibraryStatus: Decodable {
    let name: String
}

nonisolated struct UserLibraryBook: Decodable {
    let userBookId: UUID
    let userId: UUID
    let bookId: UUID
    let editionId: UUID
    var statusId: Int
    var currentPage: Int?
    var startedAt: String?
    var finishedAt: String?

    let book: LibraryBook
    let edition: LibraryBookEdition
    var status: LibraryStatus

    enum CodingKeys: String, CodingKey {
        case userBookId = "user_book_id"
        case userId = "user_id"
        case bookId = "book_id"
        case editionId = "edition_id"
        case statusId = "status_id"
        case currentPage = "current_page"
        case startedAt = "started_at"
        case finishedAt = "finished_at"

        case book = "books"
        case edition = "book_editions"
        case status
    }
}

struct LibraryBook: Decodable {
    let title: String
    let bookAuthors: [LibraryBookAuthor]
    enum CodingKeys: String, CodingKey {
            case title
            case bookAuthors = "book_authors"
        }
}

struct LibraryBookAuthor: Decodable {
    let author: LibraryAuthor

    enum CodingKeys: String, CodingKey {
        case author = "authors"
    }
}

struct LibraryAuthor: Decodable {
    let name: String
}


struct LibraryBookEdition: Decodable {
    let isbn: String?
    let numberOfPages: Int?
    let publisher: String?
    let publishedDate: String?
    let coverUrl: String?

    enum CodingKeys: String, CodingKey {
        case isbn
        case numberOfPages = "number_of_pages"
        case publisher
        case publishedDate = "published_date"
        case coverUrl = "cover_url"
    }
}

struct UpdateBookProgressParams: Encodable {
    let userBookId: UUID
    let newPage: Int
    let logDate: String

    enum CodingKeys: String, CodingKey {
        case userBookId = "p_user_book_id"
        case newPage = "p_new_page"
        case logDate = "p_log_date"
    }
}

struct UpdateBookStatusParams: Encodable {
    let statusId: Int

    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
    }
}

nonisolated struct RestartReadingResponse: Decodable {
    let statusId: Int
    let currentPage: Int
    let startedAt: String
    let finishedAt: String?

    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
        case currentPage = "current_page"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
    }
}

nonisolated struct FinishReadingResponse: Decodable {
    let statusId: Int
    let currentPage: Int?
    let startedAt: String?
    let finishedAt: String?

    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
        case currentPage = "current_page"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
    }
}

final class LibraryService {
    static let shared = LibraryService()
    init() {}
    
    // MARK: - Guardar libro del usuario
    func saveBookToLibrary(book: Book, status: BookStatus) async throws {

        let params = SaveBookParams(
            p_external_books_id: book.externalId,
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
    
    // MARK: - Obtener Status de libros
    func getBookStatusFromUserLibrary(book: Book,userId: UUID) async throws -> BookStatus? {

        var editionQuery = supabase
            .from("book_editions")
            .select("edition_id")

        if !book.externalId.isEmpty {
            editionQuery = editionQuery
                .eq("external_id", value: book.externalId)
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
    
    // MARK: - Obtener todos los libros del usuario
    func getUsersBook(userId: UUID) async throws -> [UserLibraryBook] {
        let response: [UserLibraryBook] = try await supabase
            .from("user_book")
            .select("""
                user_book_id,
                user_id,
                book_id,
                edition_id,
                status_id,
                current_page,
                started_at,
                finished_at,
                books (
                    title,
                    book_authors (
                        authors (
                            name
                        )
                    )
                ),
                book_editions (
                    isbn,
                    number_of_pages,
                    publisher,
                    published_date,
                    cover_url
                ),
                status (
                    name
                )
            """)
            .eq("user_id", value: userId)
            .execute()
            .value
        return response
    }
    
    // MARK: - Actualizar progreso de libros
    func updateBookProgress(userBookId: UUID, currentPage: Int) async throws {

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"

        let logDate = formatter.string(from: Date())

        let params = UpdateBookProgressParams(
            userBookId: userBookId,
            newPage: currentPage,
            logDate: logDate
        )

        try await supabase
            .rpc("update_book_progress", params: params)
            .execute()
    }
    
    // MARK: - Actualizar el Status del libro
    func restartReading(userBookId: UUID) async throws -> RestartReadingResponse {
        let response: RestartReadingResponse = try await supabase
            .rpc(
                "start_reading",
                params: [
                    "p_user_book_id": userBookId.uuidString,
                    "p_timezone": TimeZone.current.identifier
                ]
            )
            .single()
            .execute()
            .value
        return response
    }
    
    // MARK: - Finalizar lectura

    func finishReading(userBookId: UUID) async throws -> FinishReadingResponse {

        let response: FinishReadingResponse = try await supabase
            .rpc(
                "finish_reading",
                params: [
                    "p_user_book_id": userBookId.uuidString,
                    "p_timezone": TimeZone.current.identifier
                ]
            )
            .single()
            .execute()
            .value

        return response
    }
    
    //MARK: - Obtener libro de un usuario 
    func getUserBook(userBookId: UUID) async throws -> UserLibraryBook {

        let response: UserLibraryBook = try await supabase
            .from("user_book")
            .select("""
                user_book_id,
                user_id,
                book_id,
                edition_id,
                status_id,
                current_page,
                started_at,
                finished_at,
                books (
                    title,
                    book_authors (
                        authors (
                            name
                        )
                    )
                ),
                book_editions (
                    isbn,
                    number_of_pages,
                    publisher,
                    published_date,
                    cover_url
                ),
                status (
                    name
                )
            """)
            .eq("user_book_id", value: userBookId)
            .single()
            .execute()
            .value

        return response
    }
}
    
