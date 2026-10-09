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
    
    private var visibleBooks: [Book] {
        showAllBooks
            ? searchViewModel.books
            : Array(searchViewModel.books.prefix(3))
    }
    
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
                            ForEach(visibleBooks, id: \.externalId) { book in
                                    NavigationLink {
                                        BookDetailView(book: book)
                                    } label: {
                                        BookSearchResultRow(book: book)
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
                    
                }
                .searchable(
                    text: $searchViewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always)
                )
                .task(id: searchViewModel.searchText) {

                    let query = searchViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

                    if query.isEmpty {
                        searchViewModel.restoreInitialBooks()
                        return
                    }

                    guard query.count >= 2 else { return }

                    do {
                        try await Task.sleep(for: .milliseconds(400))

                        try Task.checkCancellation()

                        booksIsLoading = true
                        defer { booksIsLoading = false }

                        await searchViewModel.searchBooks()

                    } catch is CancellationError {
                        // El usuario siguió escribiendo
                    } catch {
                        print("Error debounce búsqueda:", error)
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
