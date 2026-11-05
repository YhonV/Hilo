import SwiftUI
import Nuke
import NukeUI

/// One request identity for every thumbnail, including palette extraction.
enum BookCoverSource {
    static func request(_ source: String?, detail: Bool = false) -> ImageRequest {
        var url = source.flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        if !["http", "https"].contains(url?.scheme?.lowercased() ?? "") || url?.host == nil {
            url = nil
        }
        if var components = url.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) }),
           components.host?.lowercased() == "covers.openlibrary.org" {
            components.path = components.path.replacingOccurrences(
                of: #"-[SML]\.jpg$"#, with: detail ? "-L.jpg" : "-M.jpg", options: .regularExpression
            )
            url = components.url
        }
        var request = ImageRequest(url: url)
        // Shared size tiers avoid storing a separate decoded copy for every view.
        request.thumbnail = .init(maxPixelSize: detail ? 1200 : 600)
        return request
    }

    static func cachedImage(_ source: String?) -> UIImage? {
        ImagePipeline.shared.cache[request(source, detail: true)]?.image
            ?? ImagePipeline.shared.cache[request(source)]?.image
    }
}

/// Keeps existing placeholders/layouts while sharing Nuke's memory and disk caches.
struct CachedBookImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content

    var body: some View {
        LazyImage(request: BookCoverSource.request(url?.absoluteString)) { state in
            if let image = state.image {
                content(.success(image))
            } else if let error = state.error {
                content(.failure(error))
            } else {
                content(.empty)
            }
        }
    }
}

extension CachedBookImage {
    init<I: View, P: View>(url: URL?, @ViewBuilder content: @escaping (Image) -> I,
                          @ViewBuilder placeholder: @escaping () -> P)
    where Content == _ConditionalContent<I, P> {
        self.url = url
        @ViewBuilder func build(_ phase: AsyncImagePhase) -> _ConditionalContent<I, P> {
            if let image = phase.image { content(image) } else { placeholder() }
        }
        self.content = build
    }
}
