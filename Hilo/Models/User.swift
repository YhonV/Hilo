//
//  User.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var username: String
    var displayName: String
    var email: String
    var profilePic: String?
    var userBio: String?
    var createdAt: Date
}
