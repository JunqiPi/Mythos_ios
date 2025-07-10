import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 10) {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    Text("Mythos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    Button(action: {
                        Task {
                            await performLogin()
                        }
                    }) {
                        if authService.apiService.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .textOnBrand))
                                    .scaleEffect(0.8)
                                Text("Signing in...")
                            }
                        } else {
                            Text("Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .primaryButton()
                    .disabled(authService.apiService.isLoading || username.isEmpty || password.isEmpty)
                    
                    Button("Don't have an account? Sign up") {
                        showingRegister = true
                    }
                    .foregroundColor(.white)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                if let errorMessage = authService.apiService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.error)
                        .font(.caption)
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
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
    
    private func performLogin() async {
        do {
            try await authService.login(username: username, password: password)
            dismiss()
        } catch {
            authService.apiService.errorMessage = error.localizedDescription
        }
    }
}