//
//  SearchView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//

import SwiftUI

struct SearchView: View {
    @State private var searchViewModel = SearchViewModel()
    
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
                    LazyVGrid(columns: columns, spacing: 26) {
                        ForEach(searchViewModel.books.indices, id: \.self) { index in
                            NavigationLink {
                                BookDetailView(book: searchViewModel.books[index])
                            } label: {
                                BookCard(book: searchViewModel.books[index])
                            }
                        }
                    }
                    .padding(.horizontal)
                    
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
                .searchable(text: $searchViewModel.searchText)
                .task {
                    await searchViewModel.loadInitialBooks()
                }
            }
        }
    }
}

#Preview {
    SearchView()
}
