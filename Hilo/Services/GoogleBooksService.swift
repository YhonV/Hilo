//
//  GoogleBooksService.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-03-26.
//
import Foundation

final class GoogleBooksService {
    
    static let shared = GoogleBooksService()
    
    private init() {}
    
    private let BASE_URL = "https://www.googleapis.com/books/v1/volumes"
    
    private let API_KEY =
    Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String ?? ""
    
    // MARK: - Búsqueda pública
    func searchBook(query: String) async throws -> [Book] {

        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanQuery.isEmpty else {return []}

        let googleQuery: String

        return try await fetchBooks(query: cleanQuery)
    }
    
    // MARK: - Petición a Google Books
    
    private func fetchBooks(query: String) async throws -> [Book] {
        var components = URLComponents(string: BASE_URL)
        
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: API_KEY),
            URLQueryItem(name: "maxResults", value: "40"),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "projection", value: "full")
        ]
        
        guard let url = components?.url else {
            throw NSError(
                domain: "Invalid URL",
                code: 0
            )
        }
        
        var retryCount = 0
        
        while retryCount < 3 {
            
            let (data, urlResponse) =
            try await URLSession.shared.data(from: url)
            
            guard let httpResponse =
                    urlResponse as? HTTPURLResponse else {
                
                throw NSError(
                    domain: "Invalid response",
                    code: 0
                )
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                
                let response = try JSONDecoder().decode(
                    GoogleBooksResponse.self,
                    from: data
                )
                
                let items =  (response.items ?? []).map { item in
                    
                    let info = item.volumeInfo
                    
                    let cover = info.imageLinks?.thumbnail
                        .replacingOccurrences(of: "http://", with: "https://") ?? ""
                    
                    //                    print("""
                    //                    ------------------------------
                    //                    ID: \(item.id)
                    //                    Título: \(info.title)
                    //                    Autores: \(info.authors ?? [])
                    //                    Tiene imageLinks: \(info.imageLinks != nil)
                    //                    Thumbnail original: \(info.imageLinks?.thumbnail ?? "NIL")
                    //                    Cover final: \(cover.isEmpty ? "VACÍA" : cover)
                    //                    ------------------------------
                    //                    """)
                    
                    return Book(
                        externalId: item.id,
                        title: info.title,
                        authors: info.authors ?? [],
                        cover: info.imageLinks?.thumbnail
                            .replacingOccurrences(
                                of: "http://",
                                with: "https://"
                            ) ?? "",
                        genre: info.categories ?? [],
                        description: info.description,
                        publishedDate: info.publishedDate,
                        numberOfPages: {
                            guard
                                let pages = info.pageCount,
                                pages > 0
                                    else {
                                return nil
                            }
                            
                            return pages
                        }(),
                        isbn: info.industryIdentifiers?
                            .first {
                                $0.type == "ISBN_13"
                            }?
                            .identifier,
                        averageRating: info.averageRating,
                        totalReviews: info.ratingsCount ?? 0,
                        editorial: info.publisher
                        ?? "Editorial desconocida",
                        language: info.language
                        ?? "unknown"
                    )
                }
                return items
            }
            
            if [429, 502, 503, 504]
                .contains(httpResponse.statusCode) {
                
                retryCount += 1
                
                if retryCount < 3 {
                    let delay = retryCount == 1 ? 1 : 2
                    
                    try await Task.sleep(
                        for: .seconds(delay)
                    )
                    
                    continue
                }
            }
            
            throw NSError(
                domain: "HTTP Error",
                code: httpResponse.statusCode
            )
        }
        
        throw NSError(
            domain: "Max retries reached",
            code: 0
        )
    }
    
}
