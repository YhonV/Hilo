//
//  UserService.swift
//  Hilo
//
//  Created by Cactu on 20-08-26.
//
import Supabase
import Foundation

struct UsernameResult: Decodable {
    let userId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

class UserService {
    
    func createUser(user: CreateUserRequest) async throws {
        try await supabase
            .from("users")
            .insert(user)
            .execute()
    }
    
    func updateUserBasicInformation(uid: UUID, username: String, displayName: String) async throws -> User{
        return try await supabase
            .from("users")
            .update(["username": username.lowercased(), "display_name": displayName])
            .eq("user_id", value: uid)
            .select()
            .single()
            .execute()
            .value
    }
    
    func getUser(uid: UUID) async throws -> User {
        try await supabase
            .from("users")
            .select()
            .eq("user_id", value: uid)
            .single()
            .execute()
            .value
    }
    
    func deleteUser() {
        
    }
    
    func isUsernameTaken(username: String) async throws -> Bool {
        let users: [UsernameResult] = try await supabase
            .from("users")
            .select("user_id")
            .eq("username", value: username.lowercased())
            .limit(1)
            .execute()
            .value

        return !users.isEmpty
    }
    
    func updateProfilePicture(uid: UUID, profilePic: String) async throws -> User {
        return try await supabase
            .from("users")
            .update([
                "profile_pic": profilePic
            ])
            .eq("user_id", value: uid)
            .select()
            .single()
            .execute()
            .value
    }
}
