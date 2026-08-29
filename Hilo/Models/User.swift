//
//  User.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {

    var id: UUID
    var username: String
    var displayName: String
    var email: String
    var profilePic: String?
    var userBio: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case username
        case displayName = "display_name"
        case email
        case profilePic = "profile_pic"
        case userBio = "user_bio"
        case createdAt = "created_at"
    }
}
