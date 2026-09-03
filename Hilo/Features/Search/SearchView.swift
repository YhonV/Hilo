//
//  SearchView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct SearchView: View {
    @State private var searchViewModel = SearchViewModel()
    @State private var booksIsLoading: Bool = false
    @State private var showLoadError = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                ScrollView {
                    if booksIsLoading {
                        LazyVGrid(columns: columns, spacing: 26) {
                            ForEach(0..<6, id: \.self) { _ in
                                BookCardSkeleton()
                            }
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 26) {
                            ForEach(searchViewModel.books.indices, id: \.self) { index in
                                NavigationLink {
                                    BookDetailView(book: searchViewModel.books[index])
                                } label: {
                                    BookCard(book: searchViewModel.books[index])
                                }
                            }
                        }
                    }
                    
                    VStack {
                        Text("Calificación")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    VStack {
                        Text("Géneros populares")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                .searchable(
                    text: $searchViewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always)
                )
                .task {
                    booksIsLoading = true
                    defer { booksIsLoading = false }
                    
                    do {
                        try await searchViewModel.loadInitialBooks()
                    } catch {
                        showLoadError = true
                    }
                }
                .onSubmit(of: .search) {
                    Task {
                        booksIsLoading = true
                        defer { booksIsLoading = false }

                        await searchViewModel.searchBooks()
                    }
                }
                .alert("No se pudieron cargar los libros", isPresented: $showLoadError) {
                    Button("Reintentar") {
                        Task {
                            booksIsLoading = true
                            defer { booksIsLoading = false }
                            
                            do {
                                try await searchViewModel.loadInitialBooks()
                            } catch {
                                showLoadError = true
                            }
                        }
                    }
                    Button("Cancelar", role: .cancel) { }
                } message: {
                    Text("Hubo un problema al conectarse con Google Books. Inténtalo nuevamente.")
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
