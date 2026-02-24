//
//  RegisterView.swift
//  Hilo
//
//  Created by Yhon Vivas on 08-02-26.
//
import SwiftUI

struct RegisterView: View {
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isLoading = false
    @State private var navigateToLogin = false
    @State private var navigateToHome = false
    @State private var errorMessage : String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("hilo")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(AppColors.primary)
                        
                        Text("join_readers_community")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
                    // Form sin el botón
                    Form {
                        Section{
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                TextField("form_name_placeholder", text: $displayName)
                                    .padding(.vertical, 8)
                            }
                            
                            HStack {
                                Image(systemName: "at")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                TextField("form_username_placeholder", text: $username)
                                    .padding(.vertical, 8)
                            }
                            
                            HStack {
                                Image(systemName: "envelope")
                                   .foregroundColor(.gray)
                                   .frame(width: 20)
                                
                                TextField("form_email_placeholder", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .padding(.vertical, 8)
                            }
                            
                        } header: {
                            Text("personal_data_section")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.titles)
                                .textCase(nil)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                        
                        Section {
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("password_placeholder", text: $password)
                                    .padding(.vertical, 8)
                            }
                            
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                
                                SecureField("confirm_password_placeholder", text: $confirmPassword)
                                    .padding(.vertical, 8)
                            }
                            
                        } header: {
                            Text("password_section")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.titles)
                                .textCase(nil)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }
                    .scrollContentBackground(.hidden)
                }
                
                // Botón flotante abajo
                Button {
                    Task {
                        do {
                            try await register(email: email, password: password)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("register_button")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppColors.primary)
                .cornerRadius(12)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 10, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(AppColors.background)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
            .navigationDestination(isPresented: $navigateToHome) { HomeView() }
        }
    }
    
    func register(email: String, password: String) async throws {
        isLoading = true
    
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty, !displayName.isEmpty else {
            errorMessage = "all_fields_required"
            showError = true
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "passwords_dont_match"
            showError = true
            isLoading = false
            return
        }
        let response = try await AuthService.shared.register(email: email, password: password)
        guard !response.userId.isEmpty else { throw NSError(domain: "RegisterError", code: 0)}
        
        let userData = User (
            userId: response.userId,
            username: username,
            displayName: displayName,
            profilePic: "",
            userBio: "",
            createdAt: Date()
        )
        
        try await FirestoreService.shared.createUser(userData)
        isLoading = false
        navigateToHome = true
        clearFields()
    }
    
    func clearFields() {
        displayName = ""
        username = ""
        email = ""
        password = ""
        confirmPassword = ""
    }
}

#Preview {
    RegisterView()
}
