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
        print(BASE_URL)
        print(API_KEY)
        var components = URLComponents(string: BASE_URL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: API_KEY)
        ]
        guard let url = components?.url else {
            throw NSError(domain: "Invalid URL", code: 0)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        let book = response.items.compactMap{
            item -> Book? in
            let info = item.volumeInfo
            
            return Book (
                title: info.title,
                author: info.authors?.first ?? "Autor desconocido",
                cover: info.imageLinks?.thumbnail.replacingOccurrences(of: "http://", with: "https://") ?? "",
                genre: info.categories ?? [],
                description: info.description,
                publishedDate: info.publishedDate,
                numberOfPages: info.pageCount ?? 0,
                isbn: info.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier,
                averageRating: info.averageRating,
                totalReviews: info.ratingsCount ?? 0
            )
        }
        return book
    }
    
}
