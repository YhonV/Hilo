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
    @State private var showLoadError: Bool = false
    @State private var showAllBooks: Bool = false
    @State private var booksToShow: Int = 3
    private var visibleBooks: [Book] {
        showAllBooks
            ? searchViewModel.books
            : Array(searchViewModel.books.prefix(3))
    }
    
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
                        ForEach(0..<3, id: \.self) { _ in
                            BookCardSkeleton()
                            Divider()
                        }
                        .padding(.horizontal)
                    } else {
                        LazyVStack(spacing: 0) {
                                ForEach(visibleBooks.indices, id: \.self) { index in
                                    NavigationLink {
                                        BookDetailView(book: searchViewModel.books[index])
                                    } label: {
                                        BookSearchResultRow(
                                            book: searchViewModel.books[index]
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                }
                            }
                            .padding(.horizontal)
                        
                        if searchViewModel.books.count > 3 {
                            Button {
                                showAllBooks.toggle()
                            } label: {
                                Text(showAllBooks ? "show_less" : "show_more")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primaryStrong)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                            .padding(.horizontal, 20)
                        }
                    }
                    
//                    VStack {
//                        Text("Calificación")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .foregroundStyle(AppColors.primary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    .padding(.horizontal)
//                    
//                    VStack {
//                        Text("Géneros populares")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .foregroundStyle(AppColors.primary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    .padding(.horizontal)
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
