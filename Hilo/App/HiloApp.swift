//
//  HiloApp.swift
//  Hilo
//
//  Created by Yhon Vivas on 31-01-26.
//

import SwiftUI
import UIKit

@main
struct HiloApp: App {

    @State private var authViewModel = AuthViewModel()
    init() {
        BookImagePipeline.configure()
        // Preserve the native tab bar material while tinting inactive icons too.
        UITabBar.appearance().unselectedItemTintColor = UIColor(named: "color-accent")?.withAlphaComponent(0.75)
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isRecoveringPassword {
                    ResetPasswordView()
                } else if authViewModel.isAuthenticated {
                    
                    MainTabView()
                        .id(authViewModel.currentUser?.id)
                } else {
                    LoginView()
                }
            }
            .disabled(authViewModel.isDeletingAccount)
            .accessibilityHidden(authViewModel.isDeletingAccount)
            .overlay {
                if authViewModel.isDeletingAccount {
                    AccountDeletionProgressView()
                }
            }
            .environment(authViewModel)
            .onOpenURL { url in
                Task { await authViewModel.handleRecoveryURL(url) }
            }
        }
    }
}
