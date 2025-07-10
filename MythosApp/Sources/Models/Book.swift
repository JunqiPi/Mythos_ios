import Foundation

// MARK: - Book Model
public struct Book: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let status: String
    public let authorName: String
    public let chapters: Int
    public let views: Int
    public let likes: Int
    public let coverUrl: String?
    public let publishedChapterCount: Int
    public let wordNumber: Int
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        status: String = "draft",
        authorName: String,
        chapters: Int = 0,
        views: Int = 0,
        likes: Int = 0,
        coverUrl: String? = nil,
        publishedChapterCount: Int = 0,
        wordNumber: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.authorName = authorName
        self.chapters = chapters
        self.views = views
        self.likes = likes
        self.coverUrl = coverUrl
        self.publishedChapterCount = publishedChapterCount
        self.wordNumber = wordNumber
    }
}

// MARK: - Book Status Helper
extension Book {
    public var statusText: String {
        switch status {
        case "draft": return "草稿"
        case "published": return "已发布"
        case "completed": return "已完结"
        default: return status
        }
    }
}