//
//  UserBooks.swift
//  Hilo
//
//  Created by Cactu on 10-09-26.
//
import Foundation

struct UserBook: Codable {
    let userBookId: UUID
    let userId: UUID
    let bookId: UUID
    let statusId: Int
    let editionId: UUID?
    let currentPage: Int
    let startedAt: Date?
    let finishedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userBookId = "user_book_id"
        case userId = "user_id"
        case bookId = "book_id"
        case statusId = "status_id"
        case editionId = "edition_id"
        case currentPage = "current_page"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
