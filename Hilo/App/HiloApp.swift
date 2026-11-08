//
//  HiloApp.swift
//  Hilo
//
//  Created by Yhon Vivas on 31-01-26.
//

import SwiftUI

@main
struct HiloApp: App {

    @State private var authViewModel = AuthViewModel()
    init() {
        BookImagePipeline.configure()
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isRecoveringPassword {
                    ResetPasswordView()
                } else if authViewModel.isAuthenticated {
                    
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environment(authViewModel)
            .onOpenURL { url in
                Task { await authViewModel.handleRecoveryURL(url) }
            }
        }
    }
}
