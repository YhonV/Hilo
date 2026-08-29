//
//  ProfileView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    private let storageService = StorageService()

    @State private var avatarURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                ScrollView {
                    VStack {
                        HStack {
                            AsyncImage(url: avatarURL) { phase in
                                switch phase {

                                case .empty:
                                    ProgressView()

                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()

                                case .failure:
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundStyle(AppColors.secondaryText)

                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(.circle)
                            
                            VStack(alignment: .leading) {
                                Spacer()
                                
                                Text(authViewModel.currentUser?.displayName ?? "Loading...")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.primary)
                                
                                Text(authViewModel.currentUser?.username ?? "@username")
                                    .font(.callout)
                                    .fontWeight(.bold)
                                    .glassEffect()
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Spacer()
                                
//                                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
//                                    .font(.callout)
//                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        NavigationLink(destination: EditProfileView()) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Editar perfil")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .buttonStyle(.glass)
                        .controlSize(.regular)
                        .tint(AppColors.accent)
                        
                        Divider()
                        
                        HStack {
                            Button {
                                
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.accent)
                                        .fontWeight(.bold)
                                    Text("24")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Leídos")
                                        .font(.callout)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .buttonStyle(.glass)
                            .buttonBorderShape(.roundedRectangle(radius: 12))
                            .controlSize(.regular)
                            
                            Button {
                                
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "book")
                                        .foregroundStyle(AppColors.accent)
                                        .fontWeight(.bold)
                                    Text("2")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Leyendo")
                                        .font(.callout)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .buttonStyle(.glass)
                            .buttonBorderShape(.roundedRectangle(radius: 12))
                            .controlSize(.regular)
                            
                            Button {
                                
                            } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "bookmark")
                                        .foregroundStyle(AppColors.accent)
                                        .fontWeight(.bold)
                                    Text("67")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Por leer")
                                        .font(.callout)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .buttonStyle(.glass)
                            .buttonBorderShape(.roundedRectangle(radius: 12))
                            .controlSize(.regular)
                        }
                        
                        VStack(spacing: 5) {
                            Text("Tu actividad")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                Button {
                                    
                                } label: {
                                    VStack(spacing: 10) {
                                        Text("Páginas leídas")
                                            .font(.callout)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        Text("6432")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        Text("Total")
                                            .font(.callout)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 130)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.roundedRectangle(radius: 12))
                                
                                Button {
                                    
                                } label: {
                                    VStack(spacing: 10) {
                                        Text("Rating promedio")
                                            .font(.callout)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Image(systemName: "star")
                                            Text("4.3")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                        }
                                        
                                        Text("de 68 reseñas")
                                            .font(.callout)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 130)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.roundedRectangle(radius: 12))
                                
                                Button {
                                    
                                } label: {
                                    VStack(spacing: 10) {
                                        Text("Género favorito")
                                            .font(.callout)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        Image(systemName: "books.vertical")
                                            .fontWeight(.bold)
                                        
                                        Text("Fantasía")
                                            .font(.callout)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 130)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.roundedRectangle(radius: 12))
                            }
                        }
                        .padding()
                        
                        
                        Button {
                            Task {
                                await authViewModel.signOut()
                            }
                        } label: {
                            Text("Cierra sesión")
                        }
                        .buttonStyle(.glassProminent)
                        .tint(Color.red)
                        
                        
                    }
                }
            }
        }
        .onAppear {
            loadAvatar()
        }   
    }
    
    func loadAvatar() {
        guard let userId = authViewModel.currentUser?.id else {
            return
        }

        do {
            let url = try storageService.getAvatarURL(userId: userId)

            // Evita mostrar una versión antigua por caché
            avatarURL = URL(
                string: "\(url.absoluteString)?v=\(Date().timeIntervalSince1970)"
            )

        } catch {
            print("Error cargando avatar:", error)
        }
    }
    
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}
