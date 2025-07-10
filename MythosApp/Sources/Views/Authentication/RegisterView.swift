import SwiftUI

// MARK: - Register View
struct RegisterView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text("Join the Mythos world")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Register Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Button(action: {
                        Task {
                            await performRegister()
                        }
                    }) {
                        if authService.apiService.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Text("Creating account...")
                                    .foregroundColor(.white)
                            }
                        } else {
                            Text("Sign Up")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.brandPink, .brandPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .disabled(authService.apiService.isLoading || !isFormValid)
                    
                    Button("Already have an account? Sign in") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                if let errorMessage = authService.apiService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 40)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.brandPink, Color.brandPurple, Color.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && 
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword &&
        email.contains("@")
    }
    
    private func performRegister() async {
        guard isFormValid else { return }
        
        do {
            try await authService.register(username: username, email: email, password: password)
            dismiss()
        } catch {
            authService.apiService.errorMessage = error.localizedDescription
        }
    }
}