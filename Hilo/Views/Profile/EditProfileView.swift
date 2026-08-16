//
//  EditProfileView.swift
//  Hilo
//
//  Created by Cactu on 15-08-26.
//

import SwiftUI

struct EditProfileView: View {
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
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        NavigationStack {
            ZStack() {
                // FONDO
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // LOGO + HEADER
                        VStack(spacing: 0) {
                            ZStack(alignment: .bottomTrailing) {
                                Image("edward_profile_pic")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(.circle)

                                Image(systemName: "pencil")
                                    .padding(8)
                                    .glassEffect(.regular, in: .circle)
                                    .clipShape(.circle)
                            }
                            Spacer()
                            Text("edit_your_profile")
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.bottom, 5)
                        
                        // TARJETA CON FORM
                        VStack(spacing: 12) {
                            // SECCIÓN: DATOS PERSONALES
                            VStack(alignment: .leading, spacing: 16) {
//                                Text("personal_data_section")
//                                    .font(.headline)
//                                    .fontWeight(.semibold)
//                                    .foregroundColor(AppColors.titles)
                                
                                // NOMBRE
                                HStack(spacing: 12) {
                                    Image(systemName: "person")
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    TextField("form_name_placeholder", text: $displayName)
                                        .autocorrectionDisabled()
                                        .focused($isFocused)
                                        .disabled(!isEditing)
                                        .foregroundStyle(
                                            !isEditing ? AppColors.titles : AppColors.secondaryText
                                        )
                                }
                                .padding()
                                .background(
                                    !isEditing
                                        ? AppColors.background.opacity(0.65)
                                        : AppColors.surface.opacity(0.45)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                                
                                // USERNAME
                                HStack(spacing: 12) {
                                    Image(systemName: "at")
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 20)
                                    
                                    TextField("form_username_placeholder", text: $username)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .focused($isFocused)
                                        .disabled(!isEditing)
                                        .foregroundStyle(
                                            !isEditing ? AppColors.titles : AppColors.secondaryText
                                        )
                                }
                                .padding()
                                .background(
                                    !isEditing
                                        ? AppColors.background.opacity(0.65)
                                        : AppColors.surface.opacity(0.45)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.border, lineWidth: 1.2)
                                )
                                .cornerRadius(12)
                            }
                            
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
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("edit_profile_button")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(isEditing ? AppColors.primaryStrong : .gray)
                            .padding(.horizontal, 20)
                            .disabled(isLoading || !isEditing)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(AppColors.surface)
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .scrollIndicators(.hidden)
                .onTapGesture {
                    isFocused = false
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(LocalizedStringKey(errorMessage ?? "error_unknown"))
            }
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Label(
                            isEditing ? "Guardar" : "Editar",
                            systemImage: isEditing ? "checkmark" : "pencil"
                        )
                    }
                }
            }
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
    EditProfileView()
}
