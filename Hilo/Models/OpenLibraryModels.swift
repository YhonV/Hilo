//
//  OpenLibraryModels.swift
//  Hilo
//
//  Created by Cactu on 08-10-26.
//
import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let numFound: Int
    let docs: [OpenLibraryBookDTO]
}

struct OpenLibraryBookDTO: Decodable {
    let key: String
    let title: String
    let authorName: [String]?
    let coverId: Int?
    let firstPublishYear: Int?
    let languages: [String]?
    let editionKeys: [String]?
    let isbns: [String]?
    let publishers: [String]?
    let numberOfPagesMedian: Int?
    let editions: OpenLibrarySearchEditionsResponse?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case authorName = "author_name"
        case coverId = "cover_i"
        case firstPublishYear = "first_publish_year"
        case languages = "language"
        case editionKeys = "edition_key"
        case isbns = "isbn"
        case publishers = "publisher"
        case numberOfPagesMedian = "number_of_pages_median"
        case editions
    }
}

struct OpenLibrarySearchEditionsResponse: Decodable {
    let docs: [OpenLibrarySearchEditionDTO]
}

struct OpenLibrarySearchEditionDTO: Decodable {
    let key: String
    let title: String
    let coverId: Int?
    let languages: [String]?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case coverId = "cover_i"
        case languages = "language"
    }
}

struct OpenLibraryEditionsResponse: Decodable {
    let entries: [OpenLibraryEditionDTO]
}

struct OpenLibraryEditionDTO: Decodable {
    let key: String
    let title: String
    let covers: [Int]?
    let languages: [OpenLibraryLanguageDTO]?
    let isbn10: [String]?
    let isbn13: [String]?
    let publishers: [String]?
    let numberOfPages: Int?
    let publishDate: String?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case covers
        case languages
        case isbn10 = "isbn_10"
        case isbn13 = "isbn_13"
        case publishers
        case numberOfPages = "number_of_pages"
        case publishDate = "publish_date"
    }
}

struct OpenLibraryLanguageDTO: Decodable {
    let key: String
}
