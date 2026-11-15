//
//  GenreBooksView.swift
//  Hilo
//
//  Created by Cactu on 12-10-26.
//


import SwiftUI

struct GenreBooksView: View {

    let genre: BookGenre

    @State private var showScrollToTop = false
    @State private var viewModel = GenreBooksViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id("top")

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.books) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookSearchResultRow(book: book)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }

                    if viewModel.isLoading {
                        ForEach(0..<3, id: \.self) { _ in
                            BookCardSkeleton()
                            Divider()
                        }
                    }

                    if viewModel.hasMoreBooks && !viewModel.isLoading {
                        Button("genre_load_more") {
                            Task {
                                await viewModel.loadBooks(for: genre)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primaryStrong)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal)
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
                            .glassEffect(
                                .regular.interactive(),
                                in: .circle
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .transition(.opacity)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(genre.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadBooks(for: genre)
        }
    }
}
