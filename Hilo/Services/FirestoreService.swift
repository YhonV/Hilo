//
//  FirestoreService.swift
//  Hilo
//
//  Created by Yhon Vivas on 01-02-26.
//
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    let db = Firestore.firestore()
    
    func saveBook(_ book: Book) async throws {
        let bookData: [String: Any] = [
            "bookId": book.bookId,
            "title": book.title,
            "author": book.author,
            "cover": book.cover,
            "genre": book.genre,
            "description": book.description as Any,
            "numberOfPages": book.numberOfPages,
            "isbn": book.isbn as Any,
            "averageRating": book.averageRating as Any,
            "totalReviews": book.totalReviews
        ]
        
        try await db.collection("books").addDocument(data: bookData)
    }
    
    func createUser(_ user: User) async throws {
        try await db.collection("users")
            .document(user.userId)
            .setData([
                "userId": user.userId,
                "username": user.username,
                "displayName": user.displayName,
                "profilePic": user.profilePic as Any,
                "userBio": user.userBio as Any,
                "createdAt": user.createdAt
            ])
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
    
}
