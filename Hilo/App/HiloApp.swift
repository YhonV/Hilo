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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environment(authViewModel)
        }
    }
}
