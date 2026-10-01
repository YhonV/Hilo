//
//  QuoteViewModel.swift
//  Hilo
//
//  Created by Cactu on 25-09-26.
//
import SwiftUI

@MainActor
@Observable
final class QuoteViewModel {
    // MARK: - Servicios
    private let quoteService = QuoteService()
    
    // MARK: - Objetos
    var quotes: [Quote] = []
    
    // MARK: - Guardar citas
    func saveQuote(userBookId: UUID, content: String, pageNumber: Int?, sourceType: SourceTypeQuote) async throws {
        let param = CreateQuoteParams(
            userBookId: userBookId,
            content: content,
            pageNumber: pageNumber,
            sourceType: sourceType
        )
        let newQuote = try await quoteService.saveQuote(request: param)
        quotes.append(newQuote)
    }
    
    // MARK: - Obtener citas
    func getQuotes(userBookId: UUID) async throws {
        quotes = try await quoteService.getQuotes(userBookId: userBookId)
    }
    
    // MARK: - Eliminar cita
    func deleteQuote(quoteId: UUID) async throws {
        try await quoteService.deleteQuote(quoteId: quoteId)
        quotes.removeAll{$0.id == quoteId}
    }
    
    // MARK: - Editar cita
    func updateQuote(quoteId: UUID, content: String, pageNumber: Int?) async throws {
        let params = UpdateQuoteParams(content: content, pageNumber: pageNumber)
        let updatedQuote = try await quoteService.updateQuote(quoteId: quoteId,request: params)

        guard let index = quotes.firstIndex(where: {
            $0.id == quoteId
        }) else {
            return
        }

        quotes[index] = updatedQuote
    }
}
