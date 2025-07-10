import Foundation

// MARK: - HTTP Method Types
public enum HTTPMethod: String, CaseIterable, Sendable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError, Sendable {
    case invalidURL
    case authenticationFailed
    case notAuthenticated
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .authenticationFailed:
            return "Authentication failed"
        case .notAuthenticated:
            return "Not authenticated"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

// MARK: - API Response Models
struct BookInteractionStatus: Codable, Sendable {
    let liked: Bool
    let starred: Bool
    let followingAuthor: Bool
}