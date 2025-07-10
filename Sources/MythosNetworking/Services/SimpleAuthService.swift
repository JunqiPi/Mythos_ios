import Foundation
import MythosCore
import Logging

// MARK: - Simple Authentication Service for MVP
@MainActor
public final class SimpleAuthService: ObservableObject {
    public static let shared = SimpleAuthService()
    
    private let apiClient: APIClient
    private let logger: Logger
    
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: User? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    public init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
        self.logger = Logger(label: "com.mythos.simpleauth")
        
        // Bind to API client authentication state
        self.isAuthenticated = apiClient.isAuthenticated
        self.currentUser = apiClient.currentUser
    }
    
    // MARK: - Login with username/password
    public func login(username: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let parameters = [
            "username": username,
            "password": password
        ]
        
        logger.info("Attempting login for username: \(username)")
        
        do {
            // Try to make the raw API call and handle whatever response we get
            let response: [String: Any] = try await apiClient.request(
                .login,
                method: .POST,
                parameters: parameters,
                requiresAuth: false
            )
            
            logger.info("Raw login response: \(response)")
            
            // Extract token and user info from response
            if let token = response["token"] as? String ?? response["data"]?["token"] as? String {
                await apiClient.setAuthToken(token)
                
                // Create a simple user object for now
                let userDict = response["user"] as? [String: Any] ?? response["data"]?["user"] as? [String: Any] ?? [:]
                
                let user = User(
                    id: userDict["id"] as? String ?? "1",
                    username: userDict["username"] as? String ?? username,
                    email: userDict["email"] as? String ?? "\(username)@example.com",
                    profile: UserProfile(),
                    settings: UserSettings(),
                    subscription: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                isAuthenticated = true
                currentUser = user
                
                logger.info("Login successful for user: \(username)")
            } else {
                throw APIError.invalidResponse
            }
            
        } catch {
            logger.error("Login failed: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Register
    public func register(username: String, email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let parameters = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        logger.info("Attempting registration for username: \(username)")
        
        do {
            let response: [String: Any] = try await apiClient.request(
                .register,
                method: .POST,
                parameters: parameters,
                requiresAuth: false
            )
            
            logger.info("Raw register response: \(response)")
            
            // For registration, we might just get user info without token
            // So we'll need to login after registration or handle token if provided
            if let token = response["token"] as? String ?? response["data"]?["token"] as? String {
                await apiClient.setAuthToken(token)
            }
            
            // Create user object
            let userDict = response["user"] as? [String: Any] ?? response["data"] as? [String: Any] ?? [:]
            
            let user = User(
                id: userDict["id"] as? String ?? UUID().uuidString,
                username: userDict["username"] as? String ?? username,
                email: userDict["email"] as? String ?? email,
                profile: UserProfile(),
                settings: UserSettings(),
                subscription: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            isAuthenticated = token != nil
            currentUser = user
            
            logger.info("Registration successful for user: \(username)")
            
            // If no token in registration response, try to login
            if token == nil {
                try await login(username: username, password: password)
            }
            
        } catch {
            logger.error("Registration failed: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Logout
    public func logout() async {
        isLoading = true
        
        defer {
            isLoading = false
        }
        
        await apiClient.clearAuthToken()
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
        
        logger.info("User logged out")
    }
}

// MARK: - Generic API Extension for raw responses
extension APIClient {
    public func request<T>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        requiresAuth: Bool = true
    ) async throws -> T where T == [String: Any] {
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        if requiresAuth, let token = UserDefaults.standard.string(forKey: "auth_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        logger.info("API Request: \(method.rawValue) \(url.absoluteString)")
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let dict = value as? [String: Any] {
                        continuation.resume(returning: dict as! T)
                    } else {
                        continuation.resume(throwing: APIError.invalidResponse)
                    }
                case .failure(let error):
                    let apiError = self.handleAFError(error, response: response.response)
                    continuation.resume(throwing: apiError)
                }
            }
        }
    }
}