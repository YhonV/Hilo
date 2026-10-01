//
//  Review.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import FirebaseFirestore

struct Review: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var bookId: String
    var rating: Double
    var comment: String?
    var publishedDate: Date
    var likes: Int
}
