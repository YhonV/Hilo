//
//  ProfileViewModel.swift
//  Hilo
//
//  Created by Cactu on 06-09-26.
//

import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Services

    private let storageService = StorageService()
    private let profileService = ProfileService()


    // MARK: - Profile

    var avatarURL: URL?
    var coverImage: UIImage?


    // MARK: - Basic stats

    var readCount: Int = 0
    var readingCount: Int = 0
    var toReadCount: Int = 0

    // MARK: - Activity

    var pagesRead: Int = 0
    var averageRating: Double = 0
    var reviewsCount: Int = 0
    var favoriteGenre: String = ""


    // MARK: - State

    var isLoading = false
    var errorMessage: String?

    // MARK: - Currently Reading
    var currentlyReadingBooks: [CurrentlyReadingBook] = []

    private var loadedUserID: UUID?
    private var lastLoadedAt: Date?
    private let cacheLifetime: TimeInterval = 300

    var isCacheFresh: Bool {
        guard let loadedUserID, let lastLoadedAt else { return false }
        return loadedUserID == currentUserID && Date().timeIntervalSince(lastLoadedAt) < cacheLifetime
    }
    private var currentUserID: UUID? { loadedUserID }

    /// Reuses the already loaded library snapshot so progress changes appear
    /// immediately when returning to ProfileView, without another network call.
    func syncFromLibrary(_ books: [UserLibraryBook]) {
        readCount = books.filter { $0.statusId == BookStatus.read.id }.count
        readingCount = books.filter { $0.statusId == BookStatus.reading.id }.count
        toReadCount = books.filter { $0.statusId == BookStatus.toRead.id }.count
        pagesRead = books.compactMap(\.currentPage).reduce(0, +)

        currentlyReadingBooks = books
            .filter { $0.statusId == BookStatus.reading.id }
            .map { book in
                CurrentlyReadingBook(
                    userBookId: book.userBookId,
                    currentPage: book.currentPage ?? 0,
                    book: CurrentBook(
                        title: book.book.title,
                        authors: book.book.bookAuthors.map {
                            CurrentBookAuthor(name: $0.author.name)
                        }
                    ),
                    edition: CurrentBookEdition(
                        numberOfPages: book.edition.numberOfPages,
                        coverURL: book.edition.coverUrl
                    )
                )
            }
    }
    
    // MARK: - Load Profile

    func loadProfileData(userId: UUID) async {

        guard !isCacheFresh || loadedUserID != userId else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        async let avatarTask: Void = loadAvatar(userId: userId)
        async let statsTask: Void = loadBasicStats(userId: userId)
        async let currentTask: Void = loadCurrentlyReading(userId: userId)
        _ = await (avatarTask, statsTask, currentTask)
        loadedUserID = userId
        lastLoadedAt = Date()
//        await loadQuotes(userId: userId)
//        await loadActivityStats(userId: userId)
    }


    // MARK: - Avatar

    private func loadAvatar(userId: UUID) async {

        do {

            let url = try storageService.getAvatarURL(userId: userId)

            guard let finalURL = URL(
                string: "\(url.absoluteString)?v=\(Date().timeIntervalSince1970)"
            ) else {
                return
            }

            avatarURL = finalURL

            let (data, _) = try await URLSession.shared.data(from: finalURL)

            guard let image = UIImage(data: data) else {
                return
            }

            coverImage = image

        } catch {

            print("Error cargando avatar:", error)
        }
    }


    // MARK: - Basic Stats

    private func loadBasicStats(userId: UUID) async {
        do {
            print("Inicia carga de estadísticas")
            let rows = try await profileService.getReadingStats(uid: userId)
            print("Devuelve información")
            readCount = rows.filter { $0.statusId == BookStatus.read.id }.count
            readingCount = rows.filter { $0.statusId == BookStatus.reading.id }.count
            toReadCount = rows.filter { $0.statusId == BookStatus.toRead.id }.count
            pagesRead = rows.compactMap(\.currentPage).reduce(0, +)

        } catch {
            print("Error cargando estadísticas:", error)
        }
    }

    // MARK: - Currently Reading

    private func loadCurrentlyReading(userId: UUID) async {
        do {
            currentlyReadingBooks = try await profileService
                .getCurrentReadingBooks(uid: userId)
        } catch {
            print("Error cargando libros actuales:", error)
        }
    }


    // MARK: - Quotes

    private func loadQuotes(userId: UUID) async {

        // TODO:
        // Obtener citas del usuario
        // Idealmente las últimas o favoritas
    }


    // MARK: - Activity Stats

    private func loadActivityStats(userId: UUID) async {

        // TODO:
        // Total páginas leídas
        // Rating promedio
        // Cantidad de reseñas
        // Género favorito
    }
}
