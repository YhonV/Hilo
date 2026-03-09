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
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // LOGO + HEADER
                        VStack(spacing: 0) {
                            Image("hilo-logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                            
                            Text("join_readers_community")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 5)
                        
                        // TARJETA CON FORM
                        VStack(spacing: 12) {
                            // SECCIÓN: DATOS PERSONALES
                            VStack(alignment: .leading, spacing: 16) {
                                Text("personal_data_section")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.titles)
                                
                                // NOMBRE
                                HStack(spacing: 12) {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    TextField("form_name_placeholder", text: $displayName)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                                
                                // USERNAME
                                HStack(spacing: 12) {
                                    Image(systemName: "at")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    TextField("form_username_placeholder", text: $username)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                                
                                // EMAIL
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    TextField("form_email_placeholder", text: $email)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                            }
                            
                            // SECCIÓN: CONTRASEÑA
                            VStack(alignment: .leading, spacing: 16) {
                                Text("password_section")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppColors.titles)
                                
                                // PASSWORD
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    SecureField("password_placeholder", text: $password)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                                
                                // CONFIRM PASSWORD
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                        .frame(width: 20)
                                    
                                    SecureField("confirm_password_placeholder", text: $confirmPassword)
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                            }
                            
                            // LINK A LOGIN
                            HStack(spacing: 4) {
                                Text("already_have_an_account")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                NavigationLink(destination: LoginView()) {
                                    Text("log_in")
                                        .font(.subheadline)
                                        .foregroundColor(AppColors.primary)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)

                // BOTÓN FIJO
                Button {
                    Task {
                        do {
                            try await register(email: email, password: password)
                        } catch {
                            isLoading = false
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
                .frame(height: 56)
                .background(AppColors.primary)
                .cornerRadius(16)
                .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 6)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .disabled(isLoading)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
            //.navigationBarHidden(true)
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
        
        let finalUsername = username.hasPrefix("@") ? username : "@" + username
        
        let usernameTaken = try await FirestoreService.shared.isUsernameTaken(finalUsername)
        if usernameTaken {
            isLoading = false
            errorMessage = "username_not_available"
            showError = true
            return
        }
        
        let response = try await AuthService.shared.register(email: email, password: password)
        let uid = response.id
        
        guard let uid = uid, !uid.isEmpty else {
                throw NSError(
                    domain: "RegisterError",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create user account"]
                )
            }
        
        let userData = User (
            username: finalUsername.lowercased(),
            displayName: displayName,
            email: email,
            profilePic: "",
            userBio: "",
            createdAt: Date()
        )
        
        try await FirestoreService.shared.createUser(userData, uid: uid)
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
