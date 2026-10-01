//
//  GoogleBooksResponse.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-03-26.
//
import Foundation

struct GoogleBooksResponse: Codable {
    var items: [BookItem]
}

struct BookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    var title:                  String
    var authors:                [String]?
    var imageLinks:             ImageLinks?
    var categories:             [String]?
    var description:            String?
    var publishedDate:          String?
    var pageCount:              Int?
    var industryIdentifiers:    [IndustryIdentifier]?
    var averageRating:          Double?
    var ratingsCount:           Int?
    var publisher:              String?
    var language:               String?
}

struct IndustryIdentifier: Codable {
    var type: String
    var identifier: String
}

struct ImageLinks: Codable {
    var thumbnail: String
}
