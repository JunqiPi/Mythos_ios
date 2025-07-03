import Foundation

// MARK: - Book Model
@frozen
public struct Book: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let coverImageURL: URL?
    public let author: Author
    public let genre: Genre
    public let tags: [String]
    public let language: String
    public let status: BookStatus
    public let publishingSchedule: PublishingSchedule?
    public let stats: BookStats
    public let pricing: BookPricing
    public let metadata: BookMetadata
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        title: String,
        description: String,
        coverImageURL: URL? = nil,
        author: Author,
        genre: Genre,
        tags: [String] = [],
        language: String = "en",
        status: BookStatus,
        publishingSchedule: PublishingSchedule? = nil,
        stats: BookStats,
        pricing: BookPricing,
        metadata: BookMetadata,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverImageURL = coverImageURL
        self.author = author
        self.genre = genre
        self.tags = tags
        self.language = language
        self.status = status
        self.publishingSchedule = publishingSchedule
        self.stats = stats
        self.pricing = pricing
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Chapter Model
@frozen
public struct Chapter: Codable, Identifiable, Sendable {
    public let id: String
    public let bookId: String
    public let title: String
    public let content: String
    public let chapterNumber: Int
    public let isPublished: Bool
    public let isFree: Bool
    public let wordCount: Int
    public let estimatedReadingTime: TimeInterval
    public let publishedAt: Date?
    public let pricing: ChapterPricing?
    public let stats: ChapterStats
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        bookId: String,
        title: String,
        content: String,
        chapterNumber: Int,
        isPublished: Bool = false,
        isFree: Bool = true,
        wordCount: Int,
        estimatedReadingTime: TimeInterval,
        publishedAt: Date? = nil,
        pricing: ChapterPricing? = nil,
        stats: ChapterStats,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.bookId = bookId
        self.title = title
        self.content = content
        self.chapterNumber = chapterNumber
        self.isPublished = isPublished
        self.isFree = isFree
        self.wordCount = wordCount
        self.estimatedReadingTime = estimatedReadingTime
        self.publishedAt = publishedAt
        self.pricing = pricing
        self.stats = stats
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Author Model
@frozen
public struct Author: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let penName: String
    public let bio: String?
    public let profileImageURL: URL?
    public let stats: AuthorStats
    public let socialLinks: SocialLinks?
    public let verificationStatus: VerificationStatus
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        userId: String,
        penName: String,
        bio: String? = nil,
        profileImageURL: URL? = nil,
        stats: AuthorStats,
        socialLinks: SocialLinks? = nil,
        verificationStatus: VerificationStatus = .unverified,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.penName = penName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.stats = stats
        self.socialLinks = socialLinks
        self.verificationStatus = verificationStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Reading Progress
@frozen
public struct ReadingProgress: Codable, Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let bookId: String
    public let chapterId: String?
    public let progress: Double // 0.0 to 1.0
    public let lastReadPosition: Int
    public let lastReadAt: Date
    public let totalReadingTime: TimeInterval
    
    public init(
        id: String,
        userId: String,
        bookId: String,
        chapterId: String? = nil,
        progress: Double,
        lastReadPosition: Int,
        lastReadAt: Date,
        totalReadingTime: TimeInterval
    ) {
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.chapterId = chapterId
        self.progress = progress
        self.lastReadPosition = lastReadPosition
        self.lastReadAt = lastReadAt
        self.totalReadingTime = totalReadingTime
    }
}

// MARK: - Supporting Models
@frozen
public struct BookStats: Codable, Sendable {
    public let views: Int
    public let likes: Int
    public let favorites: Int
    public let comments: Int
    public let rating: Double
    public let ratingCount: Int
    public let totalChapters: Int
    public let totalWords: Int
    
    public init(
        views: Int = 0,
        likes: Int = 0,
        favorites: Int = 0,
        comments: Int = 0,
        rating: Double = 0.0,
        ratingCount: Int = 0,
        totalChapters: Int = 0,
        totalWords: Int = 0
    ) {
        self.views = views
        self.likes = likes
        self.favorites = favorites
        self.comments = comments
        self.rating = rating
        self.ratingCount = ratingCount
        self.totalChapters = totalChapters
        self.totalWords = totalWords
    }
}

@frozen
public struct ChapterStats: Codable, Sendable {
    public let views: Int
    public let likes: Int
    public let comments: Int
    public let gifts: Int
    
    public init(
        views: Int = 0,
        likes: Int = 0,
        comments: Int = 0,
        gifts: Int = 0
    ) {
        self.views = views
        self.likes = likes
        self.comments = comments
        self.gifts = gifts
    }
}

@frozen
public struct AuthorStats: Codable, Sendable {
    public let totalBooks: Int
    public let totalFollowers: Int
    public let totalLikes: Int
    public let totalEarnings: Double
    
    public init(
        totalBooks: Int = 0,
        totalFollowers: Int = 0,
        totalLikes: Int = 0,
        totalEarnings: Double = 0.0
    ) {
        self.totalBooks = totalBooks
        self.totalFollowers = totalFollowers
        self.totalLikes = totalLikes
        self.totalEarnings = totalEarnings
    }
}

@frozen
public struct BookPricing: Codable, Sendable {
    public let model: PricingModel
    public let freeChapters: Int
    public let pricePerChapter: Double?
    public let subscriptionTier: SubscriptionTier?
    
    public init(
        model: PricingModel,
        freeChapters: Int = 0,
        pricePerChapter: Double? = nil,
        subscriptionTier: SubscriptionTier? = nil
    ) {
        self.model = model
        self.freeChapters = freeChapters
        self.pricePerChapter = pricePerChapter
        self.subscriptionTier = subscriptionTier
    }
}

@frozen
public struct ChapterPricing: Codable, Sendable {
    public let price: Double
    public let currency: String
    public let discount: Double?
    
    public init(
        price: Double,
        currency: String = "USD",
        discount: Double? = nil
    ) {
        self.price = price
        self.currency = currency
        self.discount = discount
    }
}

@frozen
public struct BookMetadata: Codable, Sendable {
    public let isbn: String?
    public let publishedYear: Int?
    public let ageRating: AgeRating
    public let contentWarnings: [String]
    public let series: String?
    public let seriesNumber: Int?
    
    public init(
        isbn: String? = nil,
        publishedYear: Int? = nil,
        ageRating: AgeRating = .general,
        contentWarnings: [String] = [],
        series: String? = nil,
        seriesNumber: Int? = nil
    ) {
        self.isbn = isbn
        self.publishedYear = publishedYear
        self.ageRating = ageRating
        self.contentWarnings = contentWarnings
        self.series = series
        self.seriesNumber = seriesNumber
    }
}

@frozen
public struct PublishingSchedule: Codable, Sendable {
    public let frequency: PublishingFrequency
    public let nextChapterDate: Date?
    public let timezone: String
    
    public init(
        frequency: PublishingFrequency,
        nextChapterDate: Date? = nil,
        timezone: String = "UTC"
    ) {
        self.frequency = frequency
        self.nextChapterDate = nextChapterDate
        self.timezone = timezone
    }
}

@frozen
public struct SocialLinks: Codable, Sendable {
    public let twitter: URL?
    public let instagram: URL?
    public let website: URL?
    public let discord: URL?
    
    public init(
        twitter: URL? = nil,
        instagram: URL? = nil,
        website: URL? = nil,
        discord: URL? = nil
    ) {
        self.twitter = twitter
        self.instagram = instagram
        self.website = website
        self.discord = discord
    }
}

// MARK: - Enums
public enum BookStatus: String, Codable, CaseIterable {
    case draft = "draft"
    case published = "published"
    case completed = "completed"
    case onHold = "on_hold"
    case discontinued = "discontinued"
}

public enum Genre: String, Codable, CaseIterable {
    case fantasy = "fantasy"
    case romance = "romance"
    case mystery = "mystery"
    case sciFi = "sci_fi"
    case thriller = "thriller"
    case drama = "drama"
    case comedy = "comedy"
    case horror = "horror"
    case historical = "historical"
    case contemporary = "contemporary"
    case youngAdult = "young_adult"
    case literary = "literary"
}

public enum PricingModel: String, Codable, CaseIterable {
    case free = "free"
    case freemium = "freemium"
    case payPerChapter = "pay_per_chapter"
    case subscription = "subscription"
}

public enum SubscriptionTier: String, Codable, CaseIterable {
    case basic = "basic"
    case premium = "premium"
    case vip = "vip"
}

public enum AgeRating: String, Codable, CaseIterable {
    case general = "general"
    case teen = "teen"
    case mature = "mature"
    case adult = "adult"
}

public enum PublishingFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case irregular = "irregular"
}

public enum VerificationStatus: String, Codable, CaseIterable {
    case unverified = "unverified"
    case pending = "pending"
    case verified = "verified"
    case rejected = "rejected"
} 