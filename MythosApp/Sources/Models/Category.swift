import Foundation

// MARK: - Category Models
public struct BookCategory: Identifiable, Codable, Sendable {
    public let id: Int
    public let name: String
    public let description: String
    public let icon: String
    public let bookCount: Int
    
    public init(id: Int, name: String, description: String, icon: String = "book", bookCount: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.bookCount = bookCount
    }
}

// MARK: - Character Model
public struct Character: Identifiable, Codable, Sendable {
    public let id: String
    public let name: String
    public let description: String
    public let avatarUrl: String?
    public let bookId: String
    public let likeCount: Int
    
    public init(id: String, name: String, description: String, avatarUrl: String? = nil, bookId: String, likeCount: Int = 0) {
        self.id = id
        self.name = name
        self.description = description
        self.avatarUrl = avatarUrl
        self.bookId = bookId
        self.likeCount = likeCount
    }
}

// MARK: - Ranking Types
public enum RankingType: String, CaseIterable, Sendable {
    case likes = "like_count"
    case views = "view_count"
    case stars = "starred_count"
    case newest = "created_at"
    
    public var displayName: String {
        switch self {
        case .likes: return "最受喜爱"
        case .views: return "阅读最多"
        case .stars: return "收藏最多"
        case .newest: return "最新发布"
        }
    }
    
    public var icon: String {
        switch self {
        case .likes: return "heart.fill"
        case .views: return "eye.fill"
        case .stars: return "star.fill"
        case .newest: return "clock.fill"
        }
    }
}