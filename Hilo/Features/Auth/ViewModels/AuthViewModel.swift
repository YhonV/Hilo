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

    private(set) var isDeletingAccount = false
    private(set) var accountDeletionFailed = false
    private var deletedAccountID: UUID?

    var isAuthenticated: Bool = false
    var currentUser: User?
    var avatarRevision = UUID()
    private(set) var isLoadingProfile = false
    private(set) var profileLoadFailed = false
    private var profileRequestID = UUID()
    var session: Session?
    private let userService = UserService()

    init() {
        Task { [weak self] in

            for await (event, session) in supabase.auth.authStateChanges {

                guard let self else {
                    break
                }

                if let id = session?.user.id, id == self.deletedAccountID { continue }
                if event == .passwordRecovery { self.isRecoveringPassword = true }
                self.isRestoringSession = false
                ReadingReminderService.shared.setUser(session?.user.id)
                WeeklyGoalReminderService.shared.setUser(session?.user.id)
                WeeklyGoalReminderService.shared.setTime(
                    hour: ReadingReminderService.shared.hour,
                    minute: ReadingReminderService.shared.minute
                )
                self.session = session
                self.isAuthenticated = session != nil
                guard session != nil else {
                    isAuthenticated = false
                    currentUser = nil
                    continue
                }
                
                await reloadCurrentUser()
                
            }
        }
    }

    /// Registration can finish inserting the profile after the sign-in event.
    /// Only the newest request for the active account may publish its result.
    func reloadCurrentUser() async {
        guard let userId = session?.user.id else { return }
        let requestID = UUID()
        profileRequestID = requestID
        isLoadingProfile = true
        profileLoadFailed = false
        if currentUser?.id != userId { currentUser = nil }
        defer {
            if profileRequestID == requestID { isLoadingProfile = false }
        }
        do {
            let user = try await userService.getUser(uid: userId)
            guard profileRequestID == requestID,
                  session?.user.id == userId, deletedAccountID != userId else { return }
            currentUser = user
        } catch {
            guard profileRequestID == requestID,
                  session?.user.id == userId, deletedAccountID != userId else { return }
            profileLoadFailed = true
            #if DEBUG
            print("[Hilo/Profile] load failed: \(UserService.profileErrorDiagnostic(error))")
            #endif
        }
    }

    func handleRecoveryURL(_ url: URL) async {
        guard !isDeletingAccount, url.scheme == "hilo", url.host == "auth", url.path == "/recovery",
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

    func deleteAccount() async {
        guard !isDeletingAccount, let id = session?.user.id else { return }
        isDeletingAccount = true
        accountDeletionFailed = false
        defer { isDeletingAccount = false }
        do {
            try await AccountDeletionService().deleteAccount()
        } catch {
            // Do not claim deletion or clear local state when the server has not confirmed it.
            accountDeletionFailed = true
            return
        }

        deletedAccountID = id
        ReadingReminderService.shared.setUser(nil)
        WeeklyGoalReminderService.shared.setUser(nil)
        let prefixes = ["readingReminder.\(id.uuidString).", "weeklyGoal.\(id.uuidString)."]
        for key in UserDefaults.standard.dictionaryRepresentation().keys
        where prefixes.contains(where: { key.hasPrefix($0) }) {
            UserDefaults.standard.removeObject(forKey: key)
        }
        SearchHistoryService.shared.clearHistory()
        URLCache.shared.removeAllCachedResponses()
        session = nil
        currentUser = nil
        isAuthenticated = false
        finishPasswordRecovery()
        // The pinned SDK removes the persisted local session before its network logout call.
        // A network failure here cannot undo a confirmed server-side deletion.
        try? await supabase.auth.signOut(scope: .local)
    }

    func signOut() async {
        guard !isDeletingAccount else { return }
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Error al cerrar sesión: \(error)")
        }
    }
}
