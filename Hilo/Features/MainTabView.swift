//
//  MainTabView.swift
//  Hilo
//
//  Created by Yhon Vivas on 03-03-26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0;
    
    var body: some View {
        TabView() {
            Tab("home_text_tab", systemImage: "house.fill") {
                HomeView()
            }
            Tab("search_text_tab", systemImage: "magnifyingglass", role: .search) {
                SearchView()
            }
            Tab("library_text_tab", systemImage: "books.vertical.fill") {
                LibraryView()
            }
            Tab("profile_text_tab", systemImage: "person.fill") {
                ProfileView()
            }
        }
    }
}
