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

    var isRecoveringPassword = UserDefaults.standard.bool(forKey: "passwordRecoveryPending") {
        didSet { UserDefaults.standard.set(isRecoveringPassword, forKey: "passwordRecoveryPending") }
    }
    var isRestoringSession = true
    var isOpeningRecoveryLink = false
    var recoveryLinkFailed = false

    var isAuthenticated: Bool = false
    var currentUser: User?
    var session: Session?
    private let userService = UserService()

    init() {
        Task { [weak self] in

            for await (event, session) in supabase.auth.authStateChanges {

                guard let self else {
                    break
                }

                if event == .passwordRecovery { self.isRecoveringPassword = true }
                self.isRestoringSession = false
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

    func handleRecoveryURL(_ url: URL) async {
        guard url.scheme == "hilo", url.host == "auth", url.path == "/recovery",
              !isOpeningRecoveryLink else { return }
        isRecoveringPassword = true
        isOpeningRecoveryLink = true
        recoveryLinkFailed = false
        defer { isOpeningRecoveryLink = false }
        do {
            session = try await supabase.auth.session(from: url)
        } catch {
            recoveryLinkFailed = true
        }
    }

    func finishPasswordRecovery() {
        isRecoveringPassword = false
        recoveryLinkFailed = false
    }

    func cancelPasswordRecovery() async {
        // Clear the temporary session locally before returning to sign in.
        do {
            try await supabase.auth.signOut(scope: .local)
            session = nil
            isAuthenticated = false
            currentUser = nil
            finishPasswordRecovery()
        } catch {
            recoveryLinkFailed = true
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
