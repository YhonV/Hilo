//
//  ProfileView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    var body: some View {
        VStack {
            Text("Hola desde profile")
            
            Button {
                authViewModel.singOut()
            } label: {
                Text("Cierra sesión")
            }
        }
    }
}
