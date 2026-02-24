//
//  Book.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation

struct Book {
    var bookId: String
    var title: String
    var author: String
    var cover: String
    var genre: [String]
    var description: String?
    var publishedDate: Date
    var numberOfPages: Int
    var isbn: String?
    var averageRating: Double?
    var totalReviews: Int
}
