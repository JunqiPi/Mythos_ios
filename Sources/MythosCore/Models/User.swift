import Foundation

// MARK: - User Model
@frozen
public struct User: Codable, Identifiable, Sendable {
    public let id: String
    public let username: String
    public let email: String
    public let profile: UserProfile
    public let settings: UserSettings
    public let subscription: UserSubscription?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: String,
        username: String,
        email: String,
        profile: UserProfile,
        settings: UserSettings,
        subscription: UserSubscription? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.profile = profile
        self.settings = settings
        self.subscription = subscription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - User Profile
@frozen
public struct UserProfile: Codable, Sendable {
    public let firstName: String?
    public let lastName: String?
    public let avatarURL: URL?
    public let bio: String?
    public let preferredLanguage: String
    public let timezone: String?
    public let readingStats: ReadingStats
    
    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        avatarURL: URL? = nil,
        bio: String? = nil,
        preferredLanguage: String = "en",
        timezone: String? = nil,
        readingStats: ReadingStats = ReadingStats()
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.avatarURL = avatarURL
        self.bio = bio
        self.preferredLanguage = preferredLanguage
        self.timezone = timezone
        self.readingStats = readingStats
    }
}

// MARK: - User Settings
@frozen
public struct UserSettings: Codable, Sendable {
    public let theme: AppTheme
    public let fontSize: FontSize
    public let readingMode: ReadingMode
    public let autoSync: Bool
    public let offlineMode: Bool
    public let pushNotifications: NotificationSettings
    
    public init(
        theme: AppTheme = .system,
        fontSize: FontSize = .medium,
        readingMode: ReadingMode = .comfortable,
        autoSync: Bool = true,
        offlineMode: Bool = false,
        pushNotifications: NotificationSettings = NotificationSettings()
    ) {
        self.theme = theme
        self.fontSize = fontSize
        self.readingMode = readingMode
        self.autoSync = autoSync
        self.offlineMode = offlineMode
        self.pushNotifications = pushNotifications
    }
}

// MARK: - Reading Statistics
@frozen
public struct ReadingStats: Codable, Sendable {
    public let totalBooksRead: Int
    public let totalChaptersRead: Int
    public let totalReadingTime: TimeInterval
    public let favoriteGenres: [String]
    public let currentStreak: Int
    public let longestStreak: Int
    
    public init(
        totalBooksRead: Int = 0,
        totalChaptersRead: Int = 0,
        totalReadingTime: TimeInterval = 0,
        favoriteGenres: [String] = [],
        currentStreak: Int = 0,
        longestStreak: Int = 0
    ) {
        self.totalBooksRead = totalBooksRead
        self.totalChaptersRead = totalChaptersRead
        self.totalReadingTime = totalReadingTime
        self.favoriteGenres = favoriteGenres
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }
}

// MARK: - User Subscription
@frozen
public struct UserSubscription: Codable, Sendable {
    public let id: String
    public let plan: SubscriptionPlan
    public let status: SubscriptionStatus
    public let startDate: Date
    public let endDate: Date?
    public let autoRenew: Bool
    
    public init(
        id: String,
        plan: SubscriptionPlan,
        status: SubscriptionStatus,
        startDate: Date,
        endDate: Date? = nil,
        autoRenew: Bool = true
    ) {
        self.id = id
        self.plan = plan
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.autoRenew = autoRenew
    }
}

// MARK: - Supporting Enums
public enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
}

public enum FontSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
}

public enum ReadingMode: String, Codable, CaseIterable {
    case comfortable = "comfortable"
    case compact = "compact"
    case immersive = "immersive"
}

public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case premium = "premium"
    case author = "author"
}

public enum SubscriptionStatus: String, Codable, CaseIterable {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
    case cancelled = "cancelled"
    case expired = "expired"
}

// MARK: - Notification Settings
@frozen
public struct NotificationSettings: Codable, Sendable {
    public let newChapters: Bool
    public let bookUpdates: Bool
    public let social: Bool
    public let marketing: Bool
    
    public init(
        newChapters: Bool = true,
        bookUpdates: Bool = true,
        social: Bool = false,
        marketing: Bool = false
    ) {
        self.newChapters = newChapters
        self.bookUpdates = bookUpdates
        self.social = social
        self.marketing = marketing
    }
} 