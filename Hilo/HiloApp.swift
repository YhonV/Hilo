//
//  HiloApp.swift
//  Hilo
//
//  Created by Yhon Vivas on 31-01-26.
//

import SwiftUI
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct HiloApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var authViewModel: AuthViewModel?  // ← Opcional
    
    var body: some Scene {
        WindowGroup {
            Group {
                if let authViewModel {
                    if authViewModel.isAuthenticated {
                        MainTabView()
                            .environment(authViewModel)
                    } else {
                        LoginView()
                            .environment(authViewModel)
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if authViewModel == nil {
                    authViewModel = AuthViewModel()
                }
            }
        }
    }
}
