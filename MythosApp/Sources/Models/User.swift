import Foundation

// MARK: - User Model
public struct User: Codable, Identifiable, Sendable {
    public let id: String
    public let username: String
    public let email: String
    
    public init(id: String = UUID().uuidString, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
    }
}