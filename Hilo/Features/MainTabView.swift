//
//  MainTabView.swift
//  Hilo
//
//  Created by Yhon Vivas on 03-03-26.
//

import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0;
    @State private var quoteViewModel = QuoteViewModel()
    @State private var libraryViewModel = LibraryViewModel()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("home_text_tab", systemImage: "house.fill", value: 0) {
                HomeView()
            }
            Tab("search_text_tab", systemImage: "magnifyingglass", value: 1, role: .search) {
                SearchView()
            }
            Tab("library_text_tab", systemImage: "books.vertical.fill", value: 2) {
                LibraryView()
            }
            Tab("profile_text_tab", systemImage: "person.fill", value: 3) {
                ProfileView()
            }
        }
        .tint(AppColors.accent)
        .onChange(of: selectedTab) { AppHaptics.selection() }
        .environment(quoteViewModel)
        .environment(libraryViewModel)
        .task(id: authViewModel.currentUser?.id) {
            guard let id = authViewModel.currentUser?.id else { return }
            try? await libraryViewModel.getUserBooks(userId: id)
            syncReminders()
            await refreshReminderProgress()
        }
        .onChange(of: libraryViewModel.userBooks.map { "\($0.userBookId):\($0.statusId):\($0.currentPage ?? 0):\($0.startedAt ?? "")" }) {
            syncReminders()
            Task { await refreshReminderProgress() }
        }
        .onChange(of: libraryViewModel.lastReadingAction) {
            if let id = authViewModel.currentUser?.id, let date = libraryViewModel.lastReadingAction {
                ReadingReminderService.shared.recordActivity(userID: id, at: date)
                Task { await WeeklyGoalReminderService.shared.refresh() }
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                ReadingReminderService.shared.reconcile()
                WeeklyGoalReminderService.shared.reconcile()
                Task { await refreshReminderProgress() }
            }
        }
    }

    private func refreshReminderProgress() async {
        async let activity: Void = ReadingReminderService.shared.refreshActivity()
        async let weekly: Void = WeeklyGoalReminderService.shared.refresh()
        _ = await (activity, weekly)
    }

    private func syncReminders() {
        guard let id = authViewModel.currentUser?.id,
              libraryViewModel.hasLoadedBooks(for: id) else { return }
        ReadingReminderService.shared.updateLibrary(
            userID: id,
            hasActiveReading: libraryViewModel.userBooks.contains { $0.userId == id && $0.statusId == 1 }
        )
    }
}
