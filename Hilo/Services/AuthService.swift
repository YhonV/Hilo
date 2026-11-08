//
//  AuthService.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }
    
    func singUp(email: String, password: String) async throws -> UUID{
        let response = try await supabase.auth.signUp(email: email, password: password)
        return response.user.id;
    }
    
    static let recoveryURL = URL(string: "hilo://auth/recovery")!

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email, redirectTo: Self.recoveryURL)
    }

    func updatePassword(_ password: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: password))
    }

    func currentSession() async throws -> Session {
        try await supabase.auth.session
    }
}

