import SwiftUI
import MythosCore
import MythosNetworking

public struct LoginView: View {
    @StateObject private var authService = SimpleAuthService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingRegister = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    public var onLoginSuccess: (User) -> Void
    
    public init(onLoginSuccess: @escaping (User) -> Void) {
        self.onLoginSuccess = onLoginSuccess
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Mythos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Login to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                // Login Button
                Button(action: login) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
                .padding(.horizontal, 20)
                
                // Register Link
                Button(action: {
                    showingRegister = true
                }) {
                    Text("Don't have an account? Register")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                RegisterView { user in
                    showingRegister = false
                    onLoginSuccess(user)
                }
            }
            .alert("Login Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.login(username: username, password: password)
                let user = authService.currentUser!
                await MainActor.run {
                    isLoading = false
                    onLoginSuccess(user)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    LoginView { user in
        print("Login successful for user: \(user.username)")
    }
}