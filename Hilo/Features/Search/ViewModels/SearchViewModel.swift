//
//  SearchViewModel.swift
//  Hilo
//
//  Created by Cactu on 09-08-26.
//
import SwiftUI

@Observable
class SearchViewModel {
    var books: [Book] = []
    var searchText: String = ""
    
    func loadInitialBooks () async {
        if let fetchBooks = try? await GoogleBooksService.shared.searchBook(query: "Harry Potter y la orden del fenix") {
            books = fetchBooks
        }
    }
    
}
