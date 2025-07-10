import Foundation

// MARK: - Authentication Service
@MainActor
public class AuthenticationService: ObservableObject {
    public let apiService = APIService.shared
    
    public init() {}
    
    // MARK: - Login
    public func login(username: String, password: String) async throws {
        apiService.isLoading = true
        apiService.errorMessage = nil
        
        defer { apiService.isLoading = false }
        
        let body = [
            "username": username,
            "password": password
        ]
        
        struct LoginResponse: Codable {
            let token: String?
            let user: User?
            let data: [String: String]?
            
            enum CodingKeys: String, CodingKey {
                case token, user, data
            }
        }
        
        // Make raw request since we need custom JSON parsing
        guard let url = URL(string: "\(apiService.baseURL)/auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.authenticationFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Login response: \(json)")
            
            let token = json["token"] as? String ?? (json["data"] as? [String: Any])?["token"] as? String
            let userDict = json["user"] as? [String: Any] ?? (json["data"] as? [String: Any])?["user"] as? [String: Any] ?? [:]
            
            if let token = token {
                UserDefaults.standard.set(token, forKey: "auth_token")
                
                let user = User(
                    id: userDict["id"] as? String ?? "1",
                    username: userDict["username"] as? String ?? username,
                    email: userDict["email"] as? String ?? "\(username)@example.com"
                )
                
                apiService.setAuthenticated(user)
            } else {
                throw APIError.invalidResponse
            }
        }
    }
    
    // MARK: - Register
    public func register(username: String, email: String, password: String) async throws {
        apiService.isLoading = true
        apiService.errorMessage = nil
        
        defer { apiService.isLoading = false }
        
        let body = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        guard let url = URL(string: "\(apiService.baseURL)/auth/register") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.authenticationFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let token = json["token"] as? String ?? (json["data"] as? [String: Any])?["token"] as? String
            let userDict = json["user"] as? [String: Any] ?? (json["data"] as? [String: Any])?["user"] as? [String: Any] ?? [:]
            
            if let token = token {
                UserDefaults.standard.set(token, forKey: "auth_token")
                
                let user = User(
                    id: userDict["id"] as? String ?? UUID().uuidString,
                    username: userDict["username"] as? String ?? username,
                    email: userDict["email"] as? String ?? email
                )
                
                apiService.setAuthenticated(user)
            }
        }
    }
}