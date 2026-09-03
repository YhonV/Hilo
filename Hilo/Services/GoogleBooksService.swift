//
//  GoogleBooksService.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-03-26.
//
import Foundation

class GoogleBooksService {
    static let shared = GoogleBooksService()
    private init() {}
    private let BASE_URL: String = "https://www.googleapis.com/books/v1/volumes"
    private let API_KEY: String = Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String ?? ""
    
    func searchBook(query: String) async throws -> [Book] {
        print("Starting search book")
        
        var components = URLComponents(string: BASE_URL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: API_KEY)
        ]
        guard let url = components?.url else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
    
        var retryCount: Int = 0
        while retryCount < 3 {
            
            let (data, urlResponse) = try await URLSession.shared.data(from: url)
                
            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                    throw NSError(domain: "Invalid response", code: 0)
                }
            
            if (200...299).contains(httpResponse.statusCode) {
                let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
                
                let book = response.items.map{ item in
                    let info = item.volumeInfo
                    return Book (
                        googleBookId: item.id,
                        title: info.title,
                        authors: info.authors ?? [],
                        cover: info.imageLinks?.thumbnail.replacingOccurrences(of: "http://", with: "https://") ?? "",
                        genre: info.categories ?? [],
                        description: info.description,
                        publishedDate: info.publishedDate,
                        numberOfPages: info.pageCount ?? 0,
                        isbn: info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier,
                        averageRating: info.averageRating,
                        totalReviews: info.ratingsCount ?? 0,
                        editorial: info.publisher ?? "Editorial desconocida",
                        language: info.language ?? "unknown"
                    )
                }
                
                return book
            }
        
            if [429, 502, 503, 504].contains(httpResponse.statusCode) {

                    retryCount += 1

                    print("Intento \(retryCount) falló: HTTP \(httpResponse.statusCode)")

                    if retryCount < 3 {
                        try await Task.sleep(for: .seconds(1))
                        continue
                    }
                }

                // Error no recuperable o se acabaron los intentos
                throw NSError(
                    domain: "HTTP Error",
                    code: httpResponse.statusCode
                )
            }

            throw NSError(domain: "Max retries reached", code: 0)
        }
}
