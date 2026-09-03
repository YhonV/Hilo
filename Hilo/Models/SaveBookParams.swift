//
//  SaveBookParams.swift
//  Hilo
//
//  Created by Cactu on 30-08-26.
//

struct SaveBookParams: Encodable {
    let p_google_books_id: String
    let p_title: String
    let p_status: String
    let p_description: String?
    let p_authors: [String]
    let p_genres: [String]
    let p_isbn: String?
    let p_publisher: String?
    let p_language: String?
    let p_published_date: String?
    let p_number_of_pages: Int?
    let p_cover_url: String?
}
