import Foundation
import MythosCore
import Logging

// MARK: - Book Service
@MainActor
public final class BookService: @unchecked Sendable {
    private let apiClient: APIClient
    private let logger: Logger
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.logger = Logger(label: "com.mythos.books")
    }
    
    // MARK: - Get Books by User
    public func getUserBooks() async throws -> [Book] {
        guard let currentUser = await apiClient.currentUser else {
            throw APIError.unauthorized
        }
        
        logger.info("Fetching books for user: \(currentUser.id)")
        
        let response: BooksResponse = try await apiClient.get(
            .booksByUser(userId: currentUser.id)
        )
        
        logger.info("Found \(response.books.count) books for user")
        return response.books
    }
    
    // MARK: - Get All Books
    public func getAllBooks(
        status: BookStatus? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Book] {
        logger.info("Fetching all books")
        
        var parameters: [String: Any] = [
            "limit": limit,
            "offset": offset
        ]
        
        if let status = status {
            parameters["status"] = status.rawValue
        }
        
        let response: BooksResponse = try await apiClient.get(
            .books,
            parameters: parameters,
            requiresAuth: false
        )
        
        logger.info("Found \(response.books.count) books")
        return response.books
    }
    
    // MARK: - Get Book by ID
    public func getBook(id: String) async throws -> Book {
        logger.info("Fetching book with ID: \(id)")
        
        let response: BookResponse = try await apiClient.get(
            .book(bookId: id),
            requiresAuth: false
        )
        
        logger.info("Found book: \(response.book.title)")
        return response.book
    }
    
    // MARK: - Create Book
    public func createBook(
        title: String,
        description: String,
        genre: Genre,
        tags: [String] = [],
        language: String = "en"
    ) async throws -> Book {
        logger.info("Creating new book: \(title)")
        
        let parameters: [String: Any] = [
            "title": title,
            "description": description,
            "genre": genre.rawValue,
            "tags": tags,
            "language": language,
            "status": BookStatus.draft.rawValue
        ]
        
        let response: BookResponse = try await apiClient.post(
            .createBook,
            parameters: parameters
        )
        
        logger.info("Book created successfully: \(response.book.title)")
        return response.book
    }
    
    // MARK: - Update Book
    public func updateBook(
        id: String,
        title: String? = nil,
        description: String? = nil,
        status: BookStatus? = nil
    ) async throws -> Book {
        logger.info("Updating book: \(id)")
        
        var parameters: [String: Any] = [:]
        if let title = title { parameters["title"] = title }
        if let description = description { parameters["description"] = description }
        if let status = status { parameters["status"] = status.rawValue }
        
        let response: BookResponse = try await apiClient.put(
            .updateBook(bookId: id),
            parameters: parameters
        )
        
        logger.info("Book updated successfully: \(response.book.title)")
        return response.book
    }
    
    // MARK: - Delete Book
    public func deleteBook(id: String) async throws {
        logger.info("Deleting book: \(id)")
        
        let _: EmptyResponse = try await apiClient.delete(
            .deleteBook(bookId: id)
        )
        
        logger.info("Book deleted successfully")
    }
    
    // MARK: - Get Featured Books
    public func getFeaturedBooks(limit: Int = 10) async throws -> [Book] {
        logger.info("Fetching featured books")
        
        let parameters = ["limit": limit]
        
        let response: BooksResponse = try await apiClient.get(
            .featuredBooks,
            parameters: parameters,
            requiresAuth: false
        )
        
        logger.info("Found \(response.books.count) featured books")
        return response.books
    }
    
    // MARK: - Search Books
    public func searchBooks(
        query: String,
        genre: Genre? = nil,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Book] {
        logger.info("Searching books with query: \(query)")
        
        var parameters: [String: Any] = [
            "q": query,
            "limit": limit,
            "offset": offset
        ]
        
        if let genre = genre {
            parameters["genre"] = genre.rawValue
        }
        
        let response: BooksResponse = try await apiClient.get(
            .searchBooks,
            parameters: parameters,
            requiresAuth: false
        )
        
        logger.info("Found \(response.books.count) books matching query")
        return response.books
    }
    
    // MARK: - Get Book Chapters
    public func getBookChapters(bookId: String) async throws -> [Chapter] {
        logger.info("Fetching chapters for book: \(bookId)")
        
        let response: ChaptersResponse = try await apiClient.get(
            .chapters(bookId: bookId),
            requiresAuth: false
        )
        
        logger.info("Found \(response.chapters.count) chapters")
        return response.chapters
    }
    
    // MARK: - Get Book Stats
    public func getBookStats(bookId: String) async throws -> BookStats {
        logger.info("Fetching stats for book: \(bookId)")
        
        let response: BookStatsResponse = try await apiClient.get(
            .bookStats(bookId: bookId),
            requiresAuth: false
        )
        
        logger.info("Retrieved book stats")
        return response.stats
    }
}

// MARK: - Response Models
public struct BooksResponse: Codable {
    public let books: [Book]
    public let totalCount: Int?
    public let hasMore: Bool?
    
    public init(books: [Book], totalCount: Int? = nil, hasMore: Bool? = nil) {
        self.books = books
        self.totalCount = totalCount
        self.hasMore = hasMore
    }
}

public struct BookResponse: Codable {
    public let book: Book
    public let success: Bool
    public let message: String?
    
    public init(book: Book, success: Bool = true, message: String? = nil) {
        self.book = book
        self.success = success
        self.message = message
    }
}

public struct ChaptersResponse: Codable {
    public let chapters: [Chapter]
    public let totalCount: Int?
    
    public init(chapters: [Chapter], totalCount: Int? = nil) {
        self.chapters = chapters
        self.totalCount = totalCount
    }
}

public struct BookStatsResponse: Codable {
    public let stats: BookStats
    public let success: Bool
    
    public init(stats: BookStats, success: Bool = true) {
        self.stats = stats
        self.success = success
    }
}