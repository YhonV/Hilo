//
//  Book.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import FirebaseFirestore

struct Book: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var cover: String
    var genre: [String]
    var description: String?
    var publishedDate: String?
    var numberOfPages: Int
    var isbn: String?
    var averageRating: Double?
    var totalReviews: Int
}
