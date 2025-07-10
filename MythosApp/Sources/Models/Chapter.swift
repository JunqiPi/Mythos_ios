import Foundation

// MARK: - Chapter Model
public struct Chapter: Codable, Identifiable, Sendable {
    public let id: String
    public let bookId: String
    public let chapterNumber: Int
    public let title: String
    public let status: Int
    public let isLocked: Bool
    public let creditPrice: Int
    public let wordCount: Int
    public let readingTimeMinutes: Int
    public let publishedAt: String?
    public let nextChapterId: String?
    public let prevChapterId: String?
    
    public init(
        id: String,
        bookId: String,
        chapterNumber: Int,
        title: String,
        status: Int = 1,
        isLocked: Bool = false,
        creditPrice: Int = 0,
        wordCount: Int = 0,
        readingTimeMinutes: Int = 0,
        publishedAt: String? = nil,
        nextChapterId: String? = nil,
        prevChapterId: String? = nil
    ) {
        self.id = id
        self.bookId = bookId
        self.chapterNumber = chapterNumber
        self.title = title
        self.status = status
        self.isLocked = isLocked
        self.creditPrice = creditPrice
        self.wordCount = wordCount
        self.readingTimeMinutes = readingTimeMinutes
        self.publishedAt = publishedAt
        self.nextChapterId = nextChapterId
        self.prevChapterId = prevChapterId
    }
}

// MARK: - Chapter Content Models
public struct ChapterContent: Codable, Sendable {
    public let chapter: ChapterDetail
    public let hasFullAccess: Bool
    public let unlockReason: String?
}

public struct ChapterDetail: Codable, Sendable {
    public let id: String
    public let bookId: String
    public let chapterNumber: Int
    public let title: String
    public let content: String?
    public let contentHtml: String?
    public let contentText: String?
    public let wordCount: Int
    public let status: Int
    public let isLocked: Bool
    public let creditPrice: Int
    public let publishedAt: String?
    public let book: BookInfo?
    public let nextChapter: ChapterInfo?
    public let prevChapter: ChapterInfo?
}

public struct BookInfo: Codable, Sendable {
    public let id: String
    public let title: String
    public let authorName: String
}

public struct ChapterInfo: Codable, Sendable {
    public let id: String
    public let chapterNumber: Int
    public let title: String
}