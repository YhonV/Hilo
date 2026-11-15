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
    /// Report the failure category without logging profile values or session credentials.
    static func profileErrorDiagnostic(_ error: Error) -> String {
        func path(_ context: DecodingError.Context) -> String {
            context.codingPath.map(\.stringValue).joined(separator: ".")
        }
        switch error {
        case let error as PostgrestError:
            return "database code=\(error.code ?? "unknown")"
        case DecodingError.keyNotFound(let key, let context):
            return "decode missing field=\(([path(context), key.stringValue].filter { !$0.isEmpty }).joined(separator: "."))"
        case DecodingError.valueNotFound(_, let context):
            return "decode null field=\(path(context))"
        case DecodingError.typeMismatch(_, let context):
            return "decode type mismatch field=\(path(context))"
        case DecodingError.dataCorrupted(let context):
            return "decode invalid value field=\(path(context))"
        case let error as URLError:
            return "network code=\(error.code.rawValue)"
        default:
            let error = error as NSError
            return "request domain=\(error.domain) code=\(error.code)"
        }
    }


    
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
