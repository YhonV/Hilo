//
//  AuthViewModel.swift
//  Hilo
//
//  Created by Yhon Vivas on 03-03-26.
//
import SwiftUI
import FirebaseAuth

@Observable class AuthViewModel {
    var isAuthenticated = false
    var currentUser: User?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    init() {
        authStateHandler = Auth.auth().addStateDidChangeListener {[weak self]_, user in
            Task {
                @MainActor in
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    await self?.loadUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    private func loadUserData(uid: String) async {
        do {
            let user = try await FirestoreService.shared.getUser(uid: uid)
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            print("Error cargando usuario: \(error)")
        }
    }
    
    func singOut() {
        do {
            try Auth.auth().signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            print("Error al cerrar sesión: \(error)")
        }
    }
}

