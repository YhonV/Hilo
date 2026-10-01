//
//  AuthViewModel.swift
//  Hilo
//
//  Created by Yhon Vivas on 03-03-26.
//
import SwiftUI
import Supabase

@MainActor
@Observable
class AuthViewModel {

    var isAuthenticated: Bool = false
    var currentUser: User?
    var session: Session?
    private let userService = UserService()

    init() {
        Task { [weak self] in

            for await (_, session) in supabase.auth.authStateChanges {

                guard let self else {
                    break
                }

                self.session = session
                self.isAuthenticated = session != nil
                guard let session = session else {
                    isAuthenticated = false
                    currentUser = nil
                    continue
                }
                
                let userId = session.user.id
                do {
                    currentUser = try await userService.getUser(uid: userId)
                } catch {
                    print(error)
                    currentUser = nil
                    continue
                }
                
            }
        }
    }

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Error al cerrar sesión: \(error)")
        }
    }
}
