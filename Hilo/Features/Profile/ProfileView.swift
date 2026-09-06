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
    @State private var coverImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                ScrollView {
                    VStack (spacing: 16) {
                        
                        /// **Cabecera**
                        
                        VStack(alignment: .leading) {

                            ZStack(alignment: .bottomLeading) {
                                
                                ImageGradient(
                                    image: coverImage,
                                    count: 3,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing,
                                    overlayOpacity: 0.18,
                                    saturation: 0.8
                                )
                                .frame(height: 180)
                                .frame(maxWidth: .infinity)
                                .overlay(alignment: .topTrailing) {
                                    Menu {
                                        NavigationLink("Editar perfil") {
                                            EditProfileView()
                                        }
                                        
                                        Divider()
                                        
                                        Button("Cerrar sesión", role: .destructive) {
                                            Task {
                                                await authViewModel.signOut()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "gear")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .fontWeight(.semibold)
                                            .padding(20)
                                            .padding(.top, 40)
                                    }
                                }

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
                                .frame(width: 110, height: 110)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 20,
                                        style: .continuous
                                    )
                                )
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 20,
                                        style: .continuous
                                    )
                                    .stroke(
                                        AppColors.background,
                                        lineWidth: 4
                                    )
                                }
                                .offset(y: 40)
                                .padding(.leading, 20)
                            }

                            HStack(alignment: .center) {

                                VStack(alignment: .center, spacing: 6) {

                                    Text(
                                        authViewModel.currentUser?.displayName
                                        ?? "Loading..."
                                    )
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.primaryStrong)

                                    Text(
                                        authViewModel.currentUser?.username
                                        ?? "@username"
                                    )
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(AppColors.secondaryText)
                                }

                                Spacer()

                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                            .padding(.top, 42)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                    
                        /// **Estadisticas básica**
                        
                        HStack {
                            VStack(spacing: 5) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.accent)
                                    .fontWeight(.bold)
                                Text("24")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Leídos")
                                    .font(.callout)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider().frame(width: 1, height: 55)
                            
                            VStack(spacing: 5) {
                                Image(systemName: "book")
                                    .foregroundStyle(AppColors.accent)
                                    .fontWeight(.bold)
                                Text("2")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Leyendo")
                                    .font(.callout)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider().frame(width: 1, height: 55)
                            
                            VStack(spacing: 5) {
                                Image(systemName: "bookmark")
                                    .foregroundStyle(AppColors.accent)
                                    .fontWeight(.bold)
                                Text("67")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Por leer")
                                    .font(.callout)
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        Spacer()
                        
                        /// **Leyendo actualmente**
                        
                        VStack(spacing: 5) {
                            Text("Leyendo actualmente")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                            ReadingCard()
                            
                        }
                        .padding(.horizontal, 20)
                        
                        /// **Citas del usuario**
                        
                        VStack(spacing: 5) {
                            Text("Tus citas")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    QuoteCard(
                                        quote: "Este lugar inhumano hace monstruos humanos",
                                        bookTitle: "El resplandor",
                                        author: "Stephen King",
                                        page: "82"
                                    )
                                    
                                    QuoteCard(
                                        quote: "Este lugar inhumano hace monstruos humanos",
                                        bookTitle: "El resplandor",
                                        author: "Stephen King",
                                        page: "82"
                                    )
                                }
                                
                            }
                        }
                        .padding(.horizontal, 20)
                        

                        /// **Actividad del usuario**
                        
                        VStack(spacing: 5) {
                            Text("Tu actividad")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ActivityCard(
                                        icon: "book.closed.fill",
                                        value: "6432",
                                        title: "Páginas leídas",
                                        subtitle: "Total",
                                        coverImage: coverImage
                                    )
                                    
                                    ActivityCard(
                                        icon: "star",
                                        value: "4.3",
                                        title: "Rating promedio",
                                        subtitle: "Total",
                                        coverImage: coverImage
                                    )
                                    
                                    ActivityCard(
                                        icon: "books.vertical",
                                        value: "Fantasía",
                                        title: "Género favorito",
                                        subtitle: "Total",
                                        coverImage: coverImage
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                    }
                    .padding(.bottom, 10)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .task {
            await loadAvatar()
        }
    }
    
    func loadAvatar() async {
        guard let userId = authViewModel.currentUser?.id else {
            return
        }

        do {
            let url = try storageService.getAvatarURL(userId: userId)
            
            guard let finalURL = URL(
                string: "\(url.absoluteString)?v=\(Date().timeIntervalSince1970)"
            ) else {
                return
            }
            avatarURL = finalURL
            
            let (data, _) = try await URLSession.shared.data(from: finalURL)

            guard let image = UIImage(data: data) else {
                return
            }
            coverImage = image
        } catch {
            print("Error cargando avatar:", error)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthViewModel())
}
