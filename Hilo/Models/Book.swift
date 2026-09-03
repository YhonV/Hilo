//
//  Book.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation

struct Book: Codable, Identifiable {
    var googleBookId: String
    var id: String {
            googleBookId
        }
    var title: String
    var authors: [String]
    var cover: String
    var genre: [String]
    var description: String?
    var publishedDate: String?
    var numberOfPages: Int
    var isbn: String?
    var averageRating: Double?
    var totalReviews: Int
    var editorial: String
    var language: String
}
