//
//  Quotes.swift
//  Hilo
//
//  Created by Cactu on 25-09-26.
//
import SwiftUI

nonisolated struct Quote: Decodable {
    var id: UUID
    var userBookId: UUID
    var content: String
    var pageNumber: Int?
    var sourceType: SourceTypeQuote
    var createdAt: String
    var updatedAt: String
    var bookContext: QuoteBookContext? = nil
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case userBookId = "user_book_id"
        case content = "content"
        case pageNumber = "page_number"
        case sourceType = "source_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case bookContext = "user_book"
    }
}

struct CreateQuoteParams: Encodable {
    var userBookId: UUID
    var content: String
    var pageNumber: Int?
    var sourceType: SourceTypeQuote
    
    enum CodingKeys: String, CodingKey {
        case userBookId = "user_book_id"
        case content = "content"
        case pageNumber = "page_number"
        case sourceType = "source_type"
    }
}

enum SourceTypeQuote: String, Codable {
    case ocr
    case manual
}

enum QuoteSheetMode {
    case options
    case manual
    case ocr
}

struct UpdateQuoteParams: Encodable {
    let content: String
    let pageNumber: Int?

    enum CodingKeys: String, CodingKey {
        case content
        case pageNumber = "page_number"
    }
}

// Optional so insert/update responses and quotes with unavailable relations still decode.
nonisolated struct QuoteBookContext: Decodable {
    let book: QuoteBookInfo?
    let edition: QuoteEditionInfo?

    enum CodingKeys: String, CodingKey {
        case book = "books"
        case edition = "book_editions"
    }
}

nonisolated struct QuoteBookInfo: Decodable {
    let title: String?
}

nonisolated struct QuoteEditionInfo: Decodable {
    let coverURL: String?
    let numberOfPages: Int?

    enum CodingKeys: String, CodingKey {
        case coverURL = "cover_url"
        case numberOfPages = "number_of_pages"
    }
}
