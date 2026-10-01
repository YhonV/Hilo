//
//  CreateUserRequest.swift
//  Hilo
//
//  Created by Cactu on 20-08-26.
//
import Foundation

struct CreateUserRequest: Encodable {
    var userId: UUID
    var userName: String
    var displayName: String
    var email: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "username"
        case displayName = "display_name"
        case email = "email"
         
    }
}
