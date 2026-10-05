//
//  QuoteService.swift
//  Hilo
//
//  Created by Cactu on 25-09-26.
//
import Foundation
import Supabase

class QuoteService {
    init() {}
    static let shared = QuoteService()
    
    // MARK: - Guardar cita del libro
    func saveQuote(request: CreateQuoteParams) async throws -> Quote {
        try await supabase.from("quotes").insert(request).select().single().execute().value
    }
    
    // MARK: -  Obtener todos las citas asociadas a un libro
    func getQuotes(userBookId: UUID) async throws -> [Quote] {
        let response: [Quote] = try await supabase
            .from("quotes")
            .select()
            .eq("user_book_id", value: userBookId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    // MARK: -  Obtener todos las citas del usuario
    func getAllQuotes(userId: UUID) async throws -> [Quote] {
        let response: [Quote] = try await supabase
            .from("quotes")
            .select("""
                *,
                user_book!inner(user_id)
                """)
            .eq("user_book.user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    // MARK: - Eliminar cita del usuario
    func deleteQuote(quoteId: UUID) async throws {
        try await supabase.from("quotes").delete().eq("id", value: quoteId).execute()
    }
    
    // MARK: - Editar cita
    func updateQuote(quoteId: UUID, request: UpdateQuoteParams) async throws -> Quote {
        try await supabase.from("quotes").update(request).eq("id", value: quoteId).select().single().execute().value
    }
}
