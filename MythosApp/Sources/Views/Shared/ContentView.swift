import SwiftUI

// MARK: - Content View
struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    @State private var showingLogin = false
    
    var body: some View {
        ZStack {
            if apiService.isAuthenticated {
                MainTabView()
            } else {
                // Modern Login Screen - No awkward welcome screen
                LoginView()
            }
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .onAppear {
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        // Check if user has a stored token
        if let token = UserDefaults.standard.string(forKey: "auth_token"), !token.isEmpty {
            // Could try to validate token here
        }
    }
}