//
//  GoogleBooksModels.swift
//  Hilo
//
//  Created by Cactu on 09-10-26.
//

struct GoogleBooksMetadataResponse: Decodable {
    let items: [GoogleBooksMetadataItem]?
}

struct GoogleBooksMetadataItem: Decodable {
    let volumeInfo: GoogleBooksMetadataVolumeInfo
}

struct GoogleBooksMetadataVolumeInfo: Decodable {
    let title: String?
    let authors: [String]?
    let description: String?
    let language: String?
    let industryIdentifiers: [GoogleBooksIndustryIdentifier]?
}

struct GoogleBooksIndustryIdentifier: Decodable {
    let type: String
    let identifier: String
}
