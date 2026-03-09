//
//  AuthService.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import FirebaseAuth
import Foundation

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    func register(email: String, password: String) async throws -> User{
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        let firebaseUser = result.user
        
        return User(id: firebaseUser.uid, username: "", displayName: "", email: "", createdAt: Date())
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
}

