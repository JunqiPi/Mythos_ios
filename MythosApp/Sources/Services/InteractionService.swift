import Foundation

// MARK: - Interaction Service
@MainActor
class InteractionService: ObservableObject {
    private let apiService = APIService.shared
    
    // MARK: - Toggle Book Like
    func toggleBookLike(bookId: String) async throws -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(apiService.baseURL)/interactions/book/\(bookId)/like") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Like API URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        
        print("Like API response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Like API response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let liked = json["liked"] as? Bool {
            return liked
        }
        
        throw APIError.invalidResponse
    }
    
    // MARK: - Toggle Book Star
    func toggleBookStar(bookId: String) async throws -> Bool {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(apiService.baseURL)/interactions/book/\(bookId)/star") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Star API URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        
        print("Star API response status: \(httpResponse.statusCode)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Star API response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let starred = json["starred"] as? Bool {
            return starred
        }
        
        throw APIError.invalidResponse
    }
    
    // MARK: - Get Book Interaction Status
    func getBookInteractionStatus(bookId: String) async throws -> BookInteractionStatus {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(apiService.baseURL)/interactions/user/book/\(bookId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return BookInteractionStatus(
                liked: json["liked"] as? Bool ?? false,
                starred: json["starred"] as? Bool ?? false,
                followingAuthor: json["following_author"] as? Bool ?? false
            )
        }
        
        throw APIError.invalidResponse
    }
}