import Foundation
import Alamofire
import Logging
import MythosCore

// MARK: - API Client
@MainActor
public final class APIClient: @unchecked Sendable {
    public static let shared = APIClient()
    
    private let session: Session
    private let baseURL: URL
    private let logger: Logger
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Authentication state
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var currentUser: User?
    
    public init(
        baseURL: URL = URL(string: "http://localhost:8000/api")!,
        configuration: URLSessionConfiguration = .default
    ) {
        self.baseURL = baseURL
        self.logger = Logger(label: "com.mythos.networking")
        
        // Configure JSON handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Configure session with retry policy
        let retryPolicy = RetryPolicy(
            retryLimit: 3,
            exponentialBackoffBase: 2,
            exponentialBackoffScale: 1.0
        )
        
        self.session = Session(
            configuration: configuration,
            interceptor: APIInterceptor()
        )
        
        // Load saved authentication state
        Task {
            await loadAuthenticationState()
        }
    }
    
    // MARK: - Authentication Management
    public func setAuthToken(_ token: String) async {
        UserDefaults.standard.set(token, forKey: "auth_token")
        isAuthenticated = true
        
        // Update current user
        do {
            currentUser = try await getCurrentUser()
        } catch {
            logger.error("Failed to fetch current user: \(error)")
        }
    }
    
    public func clearAuthToken() async {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "current_user")
        isAuthenticated = false
        currentUser = nil
    }
    
    private func loadAuthenticationState() async {
        guard let token = UserDefaults.standard.string(forKey: "auth_token"),
              !token.isEmpty else {
            return
        }
        
        isAuthenticated = true
        
        // Try to load cached user or fetch from server
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? decoder.decode(User.self, from: userData) {
            currentUser = user
        } else {
            do {
                currentUser = try await getCurrentUser()
            } catch {
                logger.error("Failed to fetch current user on startup: \(error)")
                await clearAuthToken()
            }
        }
    }
    
    // MARK: - Generic Request Method
    public func request<T: Codable>(
        _ endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = JSONEncoding.default,
        requiresAuth: Bool = true
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        
        // Add auth token if required and available
        if requiresAuth, let token = UserDefaults.standard.string(forKey: "auth_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        logger.info("API Request: \(method.rawValue) \(url.absoluteString)")
        if let params = parameters {
            logger.debug("Parameters: \(params)")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        if data.isEmpty {
                            // Handle empty response for operations that don't return data
                            if T.self == EmptyResponse.self {
                                continuation.resume(returning: EmptyResponse() as! T)
                            } else {
                                continuation.resume(throwing: APIError.invalidResponse)
                            }
                            return
                        }
                        
                        let decodedResponse = try self.decoder.decode(T.self, from: data)
                        continuation.resume(returning: decodedResponse)
                    } catch {
                        self.logger.error("Decoding error: \(error)")
                        continuation.resume(throwing: APIError.decodingError(error))
                    }
                    
                case .failure(let error):
                    let apiError = self.handleAFError(error, response: response.response)
                    continuation.resume(throwing: apiError)
                }
            }
        }
    }
    
    // MARK: - Convenience Methods
    public func get<T: Codable>(
        _ endpoint: APIEndpoint,
        parameters: Parameters? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint,
            method: .GET,
            parameters: parameters,
            encoding: URLEncoding.queryString,
            requiresAuth: requiresAuth
        )
    }
    
    public func post<T: Codable>(
        _ endpoint: APIEndpoint,
        parameters: Parameters? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint,
            method: .POST,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }
    
    public func put<T: Codable>(
        _ endpoint: APIEndpoint,
        parameters: Parameters? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint,
            method: .PUT,
            parameters: parameters,
            requiresAuth: requiresAuth
        )
    }
    
    public func delete<T: Codable>(
        _ endpoint: APIEndpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint,
            method: .DELETE,
            requiresAuth: requiresAuth
        )
    }
    
    // MARK: - File Upload
    public func upload<T: Codable>(
        _ endpoint: APIEndpoint,
        data: Data,
        fileName: String,
        mimeType: String,
        parameters: Parameters? = nil
    ) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint.path)
        
        var headers: HTTPHeaders = ["Accept": "application/json"]
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { formData in
                    formData.append(
                        data,
                        withName: "file",
                        fileName: fileName,
                        mimeType: mimeType
                    )
                    
                    // Add additional parameters
                    parameters?.forEach { key, value in
                        if let stringValue = value as? String,
                           let data = stringValue.data(using: .utf8) {
                            formData.append(data, withName: key)
                        }
                    }
                },
                to: url,
                headers: headers
            )
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decodedResponse = try self.decoder.decode(T.self, from: data)
                        continuation.resume(returning: decodedResponse)
                    } catch {
                        continuation.resume(throwing: APIError.decodingError(error))
                    }
                    
                case .failure(let error):
                    let apiError = self.handleAFError(error, response: response.response)
                    continuation.resume(throwing: apiError)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    private func handleAFError(_ error: AFError, response: HTTPURLResponse?) -> APIError {
        logger.error("Network error: \(error)")
        
        switch error {
        case .responseValidationFailed(let reason):
            switch reason {
            case .unacceptableStatusCode(let code):
                if code == 401 {
                    Task { await clearAuthToken() }
                    return .unauthorized
                }
                return .httpError(code, error.localizedDescription)
            default:
                return .networkError(error)
            }
        case .sessionTaskFailed(let error):
            return .networkError(error)
        default:
            return .networkError(error)
        }
    }
    
    // MARK: - User Methods
    private func getCurrentUser() async throws -> User {
        try await get(.currentUser)
    }
}

// MARK: - API Interceptor
private class APIInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if let response = request.task?.response as? HTTPURLResponse,
           response.statusCode == 401 {
            completion(.doNotRetry)
        } else {
            completion(.retry)
        }
    }
}

// MARK: - Supporting Types
public struct EmptyResponse: Codable {
    public init() {}
}

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case networkError(Error)
    case httpError(Int, String)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        }
    }
} 