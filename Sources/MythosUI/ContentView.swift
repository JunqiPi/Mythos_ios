import SwiftUI
import MythosCore
import MythosNetworking

public struct ContentView: View {
    @StateObject private var authService = SimpleAuthService.shared
    @State private var currentUser: User?
    @State private var isCheckingAuth = true
    
    public init() {}
    
    public var body: some View {
        Group {
            if isCheckingAuth {
                SplashView()
            } else if currentUser != nil {
                MyBooksView()
            } else {
                LoginView { user in
                    currentUser = user
                }
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if !isAuthenticated {
                currentUser = nil
            }
        }
        .onChange(of: authService.currentUser) { user in
            currentUser = user
        }
    }
    
    private func checkAuthenticationStatus() {
        Task {
            // Give some time for the API client to load saved auth state
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                currentUser = authService.currentUser
                isCheckingAuth = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Mythos")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}