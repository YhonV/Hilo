//
//  ProfileService.swift
//  Hilo
//
//  Created by Cactu on 06-09-26.
//
import Supabase
import Foundation

struct UserBookStatusRow: Decodable {
    let statusId: Int

    enum CodingKeys: String, CodingKey {
        case statusId = "status_id"
    }
}

struct CurrentlyReadingBook: Decodable {
    let userBookId: UUID
    let currentPage: Int
    let book: CurrentBook
    let edition: CurrentBookEdition?

    enum CodingKeys: String, CodingKey {
        case userBookId = "user_book_id"
        case currentPage = "current_page"
        case book
        case edition
    }
}

struct CurrentBook: Decodable {
    let title: String
    let authors: [CurrentBookAuthor]
}

struct CurrentBookAuthor: Decodable {
    let name: String
}

struct CurrentBookEdition: Decodable {
    let numberOfPages: Int?
    let coverURL: String?

    enum CodingKeys: String, CodingKey {
        case numberOfPages = "number_of_pages"
        case coverURL = "cover_url"
    }
}

class ProfileService {
    init() {}
    
    func getReadingStats(uid: UUID) async throws -> [UserBookStatusRow] {
        return try await supabase
            .from("user_book")
            .select("status_id")
            .eq("user_id", value: uid)
            .execute()
            .value
    }
    
    func getCurrentReadingBooks(uid: UUID) async throws -> [CurrentlyReadingBook] {
        return try await supabase
            .from("user_book")
            .select(
                """
                user_book_id,
                current_page,
                book:books (
                    title,
                    authors (
                        name
                    )
                ),
                edition:book_editions (
                    number_of_pages,
                    cover_url
                )
                """
            )
            .eq("user_id", value: uid)
            .eq("status_id", value: BookStatus.reading.id)
            .order("updated_at", ascending: false)
            .execute()
            .value
    }

}
