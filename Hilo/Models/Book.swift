//
//  Book.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation

struct Book: Codable, Identifiable {
    var externalId: String
    var id: String {
        externalId
        }
    var title: String
    var authors: [String]
    var cover: String
    var genre: [BookGenre]
    var description: String?
    var publishedDate: String?
    var numberOfPages: Int?
    var isbn: String?
    var averageRating: Double?
    var totalReviews: Int
    var editorial: String
    var language: String
}
