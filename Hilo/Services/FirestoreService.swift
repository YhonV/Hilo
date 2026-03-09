//
//  FirestoreService.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import Foundation

class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    let db = Firestore.firestore()
    
    func saveBook(_ book: Book) async throws {
        try db.collection("books").addDocument(from: book)
    }
    
    func createUser(_ user: User, uid: String) async throws {
        try db.collection("users").document(uid).setData(from: user)
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func isUsernameTaken(_ username: String) async throws -> Bool {
        let snapshot = try await db.collection("users")
            .whereField("username", isEqualTo: username.lowercased())
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func getUser(uid: String) async throws -> User {
        guard !uid.isEmpty else {
            throw FirestoreError.invalidUID
        }
        
        let docRef = db.collection("users").document(uid)
        let document = try await docRef.getDocument()
        
        guard document.exists else {
            throw FirestoreError.userNotFound
        }
        
        do {
            let user = try document.data(as: User.self)
            return user
        } catch {
            print("Error decodificando: \(error)")
            throw FirestoreError.decodingError
        }
    }
    
}


enum FirestoreError: Error, LocalizedError {
    case invalidUID
    case userNotFound
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidUID: return "ID de usuario inválido"
        case .userNotFound: return "Usuario no encontrado"
        case .decodingError: return "Error al leer datos del usuario"
        }
    }
}
