import SwiftUI

/// One decoded image supplies both the avatar and its header palette.
@MainActor
@Observable
final class ProfileAvatar {
    private(set) var image: UIImage?
    private(set) var isLoading = false
    private var userID: UUID?
    private var revision: UUID?
    private var loadedAt: Date?
    private var requestID = UUID()
    private let fetch: (UUID) async throws -> UIImage

    init(fetch: @escaping (UUID) async throws -> UIImage = ProfileAvatar.download) {
        self.fetch = fetch
    }

    func load(userID: UUID, revision: UUID) async {
        if self.userID == userID, self.revision == revision,
           image != nil, let loadedAt, Date().timeIntervalSince(loadedAt) < 300 { return }

        let request = UUID()
        requestID = request
        if self.userID != userID { image = nil }
        self.userID = userID
        self.revision = revision
        // A failed/cancelled replacement must remain retryable, even with an old image.
        loadedAt = nil
        isLoading = true
        defer { if requestID == request { isLoading = false } }

        do {
            let downloaded = try await fetch(userID)
            try Task.checkCancellation()
            guard requestID == request else { return }
            image = downloaded
            loadedAt = Date()
        } catch {
            // Keep the last good image for this account. Never cache a failed load.
            #if DEBUG
            if !(error is CancellationError) {
                print("[Hilo/Profile] avatar could not load: \((error as NSError).code)")
            }
            #endif
        }
    }

    private static func download(userID: UUID) async throws -> UIImage {
        let url = try StorageService().getAvatarURL(userId: userID)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "v", value: UUID().uuidString)]
        guard let freshURL = components?.url else { throw URLError(.badURL) }
        let request = URLRequest(url: freshURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode),
              let image = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        return image
    }
}
