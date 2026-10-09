//
//  ProfileView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    
    @State private var profileViewModel = ProfileViewModel()
    @Environment(QuoteViewModel.self) private var quoteViewModel
    @Environment(LibraryViewModel.self) private var libraryViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // FONDO
                AppColors.background.ignoresSafeArea()
                ScrollView {
                    VStack (spacing: 16) {
                        
                        /// **Cabecera**
                        
                        VStack(alignment: .leading) {

                            ZStack(alignment: .bottom) {
                                
                                ImageGradient(
                                    image: profileViewModel.coverImage,
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

                                AsyncImage(url: profileViewModel.avatarURL) { phase in
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
                            }


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

                            .frame(maxWidth: .infinity)
                            .padding(.top, 42)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                    
                        /// **Estadisticas básica**
                        
                        HStack {
                            BasicStatisticCard(value: profileViewModel.readCount, icon: "checkmark", title: "Leídos")
                            Divider().frame(width: 1, height: 55)
                            
                            BasicStatisticCard(value: profileViewModel.readingCount, icon: "book", title: "Leyendo")
                            Divider().frame(width: 1, height: 55)
                            
                            BasicStatisticCard(value: profileViewModel.toReadCount, icon: "bookmark", title: "Por leer")
                        }
                        
                        Spacer()
                        
                        /// **Leyendo actualmente**
                        
                        VStack(spacing: 5) {

                            Text("Leyendo actualmente")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(profileViewModel.currentlyReadingBooks, id: \.userBookId) { readingBook in

                                        if let book = libraryViewModel.userBooks.first(where: {
                                            $0.userBookId == readingBook.userBookId
                                        }) {
                                            NavigationLink {
                                                LibraryBookDetailView(bookDetail: book)
                                            } label: {
                                                ReadingCard(readingBook: readingBook)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        /// **Citas del usuario**
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tus citas")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 12)

                            if quoteViewModel.userQuotes.isEmpty {
                                EmptyQuoteCard(style: .surface)
                                    .frame(maxWidth: .infinity)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(quoteViewModel.userQuotes, id: \.id) { quote in
                                            QuoteCardView(
                                                quote: quote,
                                                totalPages: quote.pageNumber
                                            )
                                            .frame(width: 300)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)                        
                    }
                    .padding(.bottom, 10)
                }
                .ignoresSafeArea(edges: .top)
            }
        }
        .task {
            if let userId = authViewModel.currentUser?.id {

                await profileViewModel.loadProfileData(userId: userId)

                do {
                    try await libraryViewModel.getUserBooks(userId: userId)
                    try await quoteViewModel.getAllQuotes(userId: userId)
                } catch {
                    print("Error cargando perfil: \(error)")
                }
            }
        }
    }
}
