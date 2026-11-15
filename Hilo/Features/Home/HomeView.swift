//
//  HomeView.swift
//  Hilo
//
//  Created by Yhon Vivas on 24-02-26.
//
import SwiftUI

struct HomeView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(LibraryViewModel.self) private var libraryViewModel
    @State private var weeklyGoal = WeeklyGoalReminderService.shared
    @State private var isLoadingBooks = false
    @State private var booksLoadFailed = false
    @State private var loadedBooksForUser: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
//                        Text(String(localized: "home_text_tab"))
//                            .font(.headline)
//                            .frame(minHeight: 44, alignment: .leading)

                        if isLoadingBooks && libraryViewModel.userBooks.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 180)
                        } else if booksLoadFailed {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(String(localized: "books_load_error_title"))
                                    .font(.subheadline)
                                Button(String(localized: "common_retry")) {
                                    Task { await loadBooks() }
                                }
                                .tint(AppColors.accent)
                            }
                        } else {
                            HomeReadingSection(books: libraryViewModel.userBooks)
                        }

                        if weeklyGoal.showsOnHome {
                            HomeWeeklyGoalCard()
                                .padding(.top, 8)
                        }

                        CalendarView()
                            .padding(.top, 8)

                        if let userID = authViewModel.currentUser?.id,
                           loadedBooksForUser == userID, !isLoadingBooks, !booksLoadFailed {
                            HomeDiscoverySection(userID: userID, books: libraryViewModel.userBooks)
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
            .refreshable {
                await WeeklyGoalReminderService.shared.refresh()
            }
            .task(id: authViewModel.currentUser?.id) {
                await loadBooks()
            }
        }
    }

    private func loadBooks() async {
        guard let userID = authViewModel.currentUser?.id else { return }
        isLoadingBooks = true
        booksLoadFailed = false
        defer { isLoadingBooks = false }
        do {
            try await libraryViewModel.getUserBooks(userId: userID)
            guard !Task.isCancelled, authViewModel.currentUser?.id == userID else { return }
            loadedBooksForUser = userID
        } catch {
            guard !Task.isCancelled else { return }
            booksLoadFailed = true
        }
    }
}


#Preview {
    HomeView()
        .environment(AuthViewModel())
        .environment(LibraryViewModel())
}
