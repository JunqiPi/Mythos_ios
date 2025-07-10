import SwiftUI
import MythosCore
import MythosNetworking

public struct RegisterView: View {
    @StateObject private var authService = SimpleAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    public var onRegisterSuccess: (User) -> Void
    
    public init(onRegisterSuccess: @escaping (User) -> Void) {
        self.onRegisterSuccess = onRegisterSuccess
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Join the Mythos community")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Registration Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                // Validation Messages
                if !validationErrors.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(validationErrors, id: \.self) { error in
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Register Button
                Button(action: register) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Register")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(isLoading || !isFormValid)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Registration Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var validationErrors: [String] {
        var errors: [String] = []
        
        if !username.isEmpty && username.count < 3 {
            errors.append("Username must be at least 3 characters")
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            errors.append("Please enter a valid email address")
        }
        
        if !password.isEmpty && password.count < 6 {
            errors.append("Password must be at least 6 characters")
        }
        
        if !confirmPassword.isEmpty && password != confirmPassword {
            errors.append("Passwords do not match")
        }
        
        return errors
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        username.count >= 3 &&
        password.count >= 6 &&
        password == confirmPassword &&
        isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func register() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                try await authService.register(
                    username: username,
                    email: email,
                    password: password
                )
                let user = authService.currentUser!
                await MainActor.run {
                    isLoading = false
                    onRegisterSuccess(user)
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
    RegisterView { user in
        print("Registration successful for user: \(user.username)")
    }
}