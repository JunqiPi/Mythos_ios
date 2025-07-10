import Foundation
import SwiftUI

// MARK: - Core API Service
@MainActor
public class APIService: ObservableObject {
    public static let shared = APIService()
    
    public init() {}
    
    @Published public var isAuthenticated = false
    @Published public var currentUser: User?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    public let baseURL = "http://localhost:8000/api"
    
    // MARK: - Authentication State Management
    public func setAuthenticated(_ user: User) {
        isAuthenticated = true
        currentUser = user
    }
    
    public func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        isAuthenticated = false
        currentUser = nil
    }
    
    // MARK: - Generic Request Method
    public func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if requiresAuth, let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}