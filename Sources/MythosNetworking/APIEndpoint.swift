import Foundation

// MARK: - API Endpoint
public enum APIEndpoint {
    // MARK: - Authentication
    case login
    case register
    case logout
    case refreshToken
    case forgotPassword
    case resetPassword(token: String)
    case verifyEmail(token: String)
    case currentUser
    
    // MARK: - User Management
    case userProfile(userId: String)
    case updateUserProfile(userId: String)
    case userSettings(userId: String)
    case updateUserSettings(userId: String)
    case deleteUser(userId: String)
    
    // MARK: - Books
    case books
    case book(bookId: String)
    case createBook
    case updateBook(bookId: String)
    case deleteBook(bookId: String)
    case booksByUser(userId: String)
    case booksByGenre(genre: String)
    case featuredBooks
    case trendingBooks
    case bookStats(bookId: String)
    
    // MARK: - Chapters
    case chapters(bookId: String)
    case chapter(bookId: String, chapterId: String)
    case createChapter(bookId: String)
    case updateChapter(bookId: String, chapterId: String)
    case deleteChapter(bookId: String, chapterId: String)
    case publishChapter(bookId: String, chapterId: String)
    case chapterStats(chapterId: String)
    
    // MARK: - Authors
    case authors
    case author(authorId: String)
    case createAuthor
    case updateAuthor(authorId: String)
    case authorBooks(authorId: String)
    case authorStats(authorId: String)
    case followAuthor(authorId: String)
    case unfollowAuthor(authorId: String)
    case authorFollowers(authorId: String)
    
    // MARK: - Reading
    case readingProgress(bookId: String)
    case updateReadingProgress(bookId: String)
    case readingHistory
    case markAsRead(chapterId: String)
    case readingLists
    case createReadingList
    case updateReadingList(listId: String)
    case deleteReadingList(listId: String)
    case addToReadingList(listId: String, bookId: String)
    case removeFromReadingList(listId: String, bookId: String)
    
    // MARK: - Search
    case search
    case searchBooks
    case searchAuthors
    case searchAdvanced
    case searchSuggestions
    
    // MARK: - Comments & Reviews
    case comments(bookId: String)
    case createComment(bookId: String)
    case updateComment(commentId: String)
    case deleteComment(commentId: String)
    case likeComment(commentId: String)
    case unlikeComment(commentId: String)
    
    // MARK: - Interactions
    case likeBook(bookId: String)
    case unlikeBook(bookId: String)
    case favoriteBook(bookId: String)
    case unfavoriteBook(bookId: String)
    case rateBook(bookId: String)
    case shareBook(bookId: String)
    
    // MARK: - Credits & Payments
    case creditBalance
    case creditTransactions
    case purchaseCredits
    case chapterPurchases
    case purchaseChapter(chapterId: String)
    case subscriptions
    case createSubscription
    case cancelSubscription(subscriptionId: String)
    
    // MARK: - Support & Gifts
    case supportGifts
    case sendGift(authorId: String)
    case giftHistory
    case receivedGifts
    
    // MARK: - Writing Tools
    case characters(bookId: String)
    case createCharacter(bookId: String)
    case updateCharacter(characterId: String)
    case deleteCharacter(characterId: String)
    
    case worldviews(bookId: String)
    case createWorldview(bookId: String)
    case updateWorldview(worldviewId: String)
    case deleteWorldview(worldviewId: String)
    
    case outlines(bookId: String)
    case createOutline(bookId: String)
    case updateOutline(outlineId: String)
    case deleteOutline(outlineId: String)
    
    case settings(bookId: String)
    case updateSettings(bookId: String)
    
    // MARK: - Advanced Writing
    case writingAnalytics(bookId: String)
    case writingInsights(authorId: String)
    case collaborationInvite(chapterId: String)
    case acceptCollaboration(inviteId: String)
    case declineCollaboration(inviteId: String)
    
    // MARK: - Admin
    case adminDashboard
    case adminUsers
    case adminBooks
    case adminReports
    case banUser(userId: String)
    case unbanUser(userId: String)
    
    // MARK: - Achievements
    case achievements
    case userAchievements(userId: String)
    case unlockAchievement(achievementId: String)
}

// MARK: - Path Generation
extension APIEndpoint {
    public var path: String {
        switch self {
        // Authentication
        case .login: return "/auth/login"
        case .register: return "/auth/register"
        case .logout: return "/auth/logout"
        case .refreshToken: return "/auth/refresh"
        case .forgotPassword: return "/auth/forgot-password"
        case .resetPassword(let token): return "/auth/reset-password/\(token)"
        case .verifyEmail(let token): return "/auth/verify-email/\(token)"
        case .currentUser: return "/auth/me"
        
        // User Management
        case .userProfile(let userId): return "/users/\(userId)"
        case .updateUserProfile(let userId): return "/users/\(userId)"
        case .userSettings(let userId): return "/users/\(userId)/settings"
        case .updateUserSettings(let userId): return "/users/\(userId)/settings"
        case .deleteUser(let userId): return "/users/\(userId)"
        
        // Books
        case .books: return "/books"
        case .book(let bookId): return "/books/\(bookId)"
        case .createBook: return "/books"
        case .updateBook(let bookId): return "/books/\(bookId)"
        case .deleteBook(let bookId): return "/books/\(bookId)"
        case .booksByUser(let userId): return "/books/user/\(userId)"
        case .booksByGenre(let genre): return "/books/genre/\(genre)"
        case .featuredBooks: return "/books/featured"
        case .trendingBooks: return "/books/trending"
        case .bookStats(let bookId): return "/books/\(bookId)/stats"
        
        // Chapters
        case .chapters(let bookId): return "/books/\(bookId)/chapters"
        case .chapter(let bookId, let chapterId): return "/books/\(bookId)/chapters/\(chapterId)"
        case .createChapter(let bookId): return "/books/\(bookId)/chapters"
        case .updateChapter(let bookId, let chapterId): return "/books/\(bookId)/chapters/\(chapterId)"
        case .deleteChapter(let bookId, let chapterId): return "/books/\(bookId)/chapters/\(chapterId)"
        case .publishChapter(let bookId, let chapterId): return "/books/\(bookId)/chapters/\(chapterId)/publish"
        case .chapterStats(let chapterId): return "/chapters/\(chapterId)/stats"
        
        // Authors
        case .authors: return "/author"
        case .author(let authorId): return "/author/\(authorId)"
        case .createAuthor: return "/author"
        case .updateAuthor(let authorId): return "/author/\(authorId)"
        case .authorBooks(let authorId): return "/author/\(authorId)/books"
        case .authorStats(let authorId): return "/author/\(authorId)/stats"
        case .followAuthor(let authorId): return "/author/\(authorId)/follow"
        case .unfollowAuthor(let authorId): return "/author/\(authorId)/unfollow"
        case .authorFollowers(let authorId): return "/author/\(authorId)/followers"
        
        // Reading
        case .readingProgress(let bookId): return "/reading-progress/\(bookId)"
        case .updateReadingProgress(let bookId): return "/reading-progress/\(bookId)"
        case .readingHistory: return "/reading-progress/history"
        case .markAsRead(let chapterId): return "/reading-progress/chapter/\(chapterId)"
        case .readingLists: return "/reading-lists"
        case .createReadingList: return "/reading-lists"
        case .updateReadingList(let listId): return "/reading-lists/\(listId)"
        case .deleteReadingList(let listId): return "/reading-lists/\(listId)"
        case .addToReadingList(let listId, let bookId): return "/reading-lists/\(listId)/books/\(bookId)"
        case .removeFromReadingList(let listId, let bookId): return "/reading-lists/\(listId)/books/\(bookId)"
        
        // Search
        case .search: return "/search"
        case .searchBooks: return "/search/books"
        case .searchAuthors: return "/search/authors"
        case .searchAdvanced: return "/search/advanced"
        case .searchSuggestions: return "/search/suggestions"
        
        // Comments & Reviews
        case .comments(let bookId): return "/books/\(bookId)/comments"
        case .createComment(let bookId): return "/books/\(bookId)/comments"
        case .updateComment(let commentId): return "/comments/\(commentId)"
        case .deleteComment(let commentId): return "/comments/\(commentId)"
        case .likeComment(let commentId): return "/comments/\(commentId)/like"
        case .unlikeComment(let commentId): return "/comments/\(commentId)/unlike"
        
        // Interactions
        case .likeBook(let bookId): return "/interactions/books/\(bookId)/like"
        case .unlikeBook(let bookId): return "/interactions/books/\(bookId)/unlike"
        case .favoriteBook(let bookId): return "/interactions/books/\(bookId)/favorite"
        case .unfavoriteBook(let bookId): return "/interactions/books/\(bookId)/unfavorite"
        case .rateBook(let bookId): return "/interactions/books/\(bookId)/rate"
        case .shareBook(let bookId): return "/interactions/books/\(bookId)/share"
        
        // Credits & Payments
        case .creditBalance: return "/credits/balance"
        case .creditTransactions: return "/credits/transactions"
        case .purchaseCredits: return "/credits/purchase"
        case .chapterPurchases: return "/chapter-purchases"
        case .purchaseChapter(let chapterId): return "/chapter-purchases/\(chapterId)"
        case .subscriptions: return "/payments/subscriptions"
        case .createSubscription: return "/payments/subscriptions"
        case .cancelSubscription(let subscriptionId): return "/payments/subscriptions/\(subscriptionId)/cancel"
        
        // Support & Gifts
        case .supportGifts: return "/support-gifts"
        case .sendGift(let authorId): return "/support-gifts/send/\(authorId)"
        case .giftHistory: return "/support-gifts/history"
        case .receivedGifts: return "/support-gifts/received"
        
        // Writing Tools
        case .characters(let bookId): return "/books/\(bookId)/characters"
        case .createCharacter(let bookId): return "/books/\(bookId)/characters"
        case .updateCharacter(let characterId): return "/characters/\(characterId)"
        case .deleteCharacter(let characterId): return "/characters/\(characterId)"
        
        case .worldviews(let bookId): return "/books/\(bookId)/worldviews"
        case .createWorldview(let bookId): return "/books/\(bookId)/worldviews"
        case .updateWorldview(let worldviewId): return "/worldviews/\(worldviewId)"
        case .deleteWorldview(let worldviewId): return "/worldviews/\(worldviewId)"
        
        case .outlines(let bookId): return "/books/\(bookId)/outlines"
        case .createOutline(let bookId): return "/books/\(bookId)/outlines"
        case .updateOutline(let outlineId): return "/outlines/\(outlineId)"
        case .deleteOutline(let outlineId): return "/outlines/\(outlineId)"
        
        case .settings(let bookId): return "/books/\(bookId)/settings"
        case .updateSettings(let bookId): return "/books/\(bookId)/settings"
        
        // Advanced Writing
        case .writingAnalytics(let bookId): return "/advanced-writing/analytics/\(bookId)"
        case .writingInsights(let authorId): return "/advanced-writing/insights/\(authorId)"
        case .collaborationInvite(let chapterId): return "/advanced-writing/collaboration/\(chapterId)/invite"
        case .acceptCollaboration(let inviteId): return "/advanced-writing/collaboration/\(inviteId)/accept"
        case .declineCollaboration(let inviteId): return "/advanced-writing/collaboration/\(inviteId)/decline"
        
        // Admin
        case .adminDashboard: return "/admin/dashboard"
        case .adminUsers: return "/admin/users"
        case .adminBooks: return "/admin/books"
        case .adminReports: return "/admin/reports"
        case .banUser(let userId): return "/admin/users/\(userId)/ban"
        case .unbanUser(let userId): return "/admin/users/\(userId)/unban"
        
        // Achievements
        case .achievements: return "/achievements"
        case .userAchievements(let userId): return "/achievements/user/\(userId)"
        case .unlockAchievement(let achievementId): return "/achievements/\(achievementId)/unlock"
        }
    }
} 