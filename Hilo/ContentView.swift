//
//  ContentView.swift
//  Hilo
//
//  Created by Yhon Vivas on 31-01-26.
//

import SwiftUI

struct ContentView: View {
    
    let testBook = Book(
        bookId: UUID().uuidString,
        title: "Cien años de soledad",
        author: "Gabriel García Márquez",
        cover: "https://covers.openlibrary.org/b/id/12345-L.jpg",
        genre: ["Ficción", "Realismo mágico"],
        description: "La historia de la familia Buendía a lo largo de siete generaciones",
        publishedDate: Date(),
        numberOfPages: 417,
        isbn: "9780307474728",
        averageRating: 4.5,
        totalReviews: 1250
    )
    
    var body: some View {
        VStack {
            HStack {
                Button("Sign in") {
                    Task {
                        do {
                            try await AuthService.shared.signIn(email: "test@gmail.com", password: "123456789")
                            print("Usuario ingresó correctamente")
                        }
                        catch {
                            print("Error: \(error)")
                        }
                    }
                }
                
                Button("Register") {
                    Task {
                        do {
                            try await AuthService.shared.register(email: "test@gmail.com", password: "123456789")
                            print("Usuario registrado")
                        }
                        catch {
                            print("Error: \(error)")
                        }
                    }
                }
            }
            .buttonStyle(.bordered)
            
            HStack {
                Button("Guardar un libro") {
                    Task{
                        do {
                            try await FirestoreService.shared.saveBook(testBook)
                        }
                        catch {
                            print("Error: \(error)")
                        }
                    }
                }
            }
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
