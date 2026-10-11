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
    @State private var showScrollToTop = false
    
    private var bestMatches: [Book] {
        Array(searchViewModel.books.prefix(3))
    }

    private var otherResults: [Book] {
        Array(searchViewModel.books.dropFirst(3))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                        if booksIsLoading {
                            ForEach(0..<3, id: \.self) { _ in
                                BookCardSkeleton()
                                Divider()
                            }
                            .padding(.horizontal)
                        } else if !searchViewModel.books.isEmpty {

                            HStack(spacing: 8) {
                                Image(systemName: "book.closed")
                                    .foregroundStyle(AppColors.primaryStrong)
                                Text("Mejores coincidencias")
                                    .font(.headline)
                                Spacer()
                                Text("Top \(bestMatches.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 12)

                        
                            LazyVStack(spacing: 0) {
                                ForEach(bestMatches, id: \.externalId) { book in
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
                            
                            if !otherResults.isEmpty {
                                AdditionalSearchResultsView(books: otherResults)
                                    .padding(.horizontal)
                                    .padding(.top, 24)
                            }
                            
                            if !searchViewModel.recommendedBooks.isEmpty {
                                RecommendedBooksSectionView(
                                    books: searchViewModel.recommendedBooks,
                                    title: "Más libros del mismo autor"
                                )
                                .padding(.top, 24)
                            }
                        }
                    }
                    .onScrollGeometryChange(for: Bool.self) { geometry in
                        geometry.contentOffset.y > 300
                    } action: { _, isScrolled in
                        showScrollToTop = isScrolled
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if showScrollToTop {
                            Button {
                                withAnimation(.smooth) {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            } label: {
                                Image(systemName: "arrow.up")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.primaryStrong)
                                    .frame(width: 48, height: 48)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .transition(.opacity)
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
