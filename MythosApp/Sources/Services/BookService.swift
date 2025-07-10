import Foundation

// MARK: - Book Service
@MainActor
class BookService: ObservableObject {
    private let apiService = APIService.shared
    
    // MARK: - Get All Books
    func getAllBooks() async throws -> [Book] {
        guard let url = URL(string: "\(apiService.baseURL)/books") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let booksArray = json["books"] as? [[String: Any]] ?? json["data"] as? [[String: Any]] ?? []
            
            return booksArray.compactMap { bookDict -> Book? in
                guard let title = bookDict["title"] as? String else { return nil }
                
                return Book(
                    id: bookDict["id"] as? String ?? UUID().uuidString,
                    title: title,
                    description: bookDict["description"] as? String ?? "",
                    status: "published",
                    authorName: bookDict["author_name"] as? String ?? "Unknown",
                    chapters: bookDict["chapters"] as? Int ?? 0,
                    views: bookDict["views"] as? Int ?? bookDict["read_count"] as? Int ?? 0,
                    likes: bookDict["likes"] as? Int ?? bookDict["like_count"] as? Int ?? 0,
                    coverUrl: bookDict["cover_url"] as? String,
                    publishedChapterCount: bookDict["published_chapter_count"] as? Int ?? 0,
                    wordNumber: bookDict["word_number"] as? Int ?? 0
                )
            }
        }
        
        return []
    }
    
    // MARK: - Get Starred Books
    func getStarredBooks() async throws -> [Book] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        // First get starred book IDs
        guard let starsUrl = URL(string: "\(apiService.baseURL)/interactions/user/stars") else {
            throw APIError.invalidURL
        }
        
        var starsRequest = URLRequest(url: starsUrl)
        starsRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (starsData, starsResponse) = try await URLSession.shared.data(for: starsRequest)
        
        guard let httpStarsResponse = starsResponse as? HTTPURLResponse,
              httpStarsResponse.statusCode == 200 else {
            print("Starred books API error: \((starsResponse as? HTTPURLResponse)?.statusCode ?? -1)")
            if let responseString = String(data: starsData, encoding: .utf8) {
                print("Starred books error response: \(responseString)")
            }
            throw APIError.requestFailed
        }
        
        var starredBookIds: [Int] = []
        
        if let starsJson = try JSONSerialization.jsonObject(with: starsData) as? [String: Any] {
            print("Starred books API response: \(starsJson)")
            
            if let booksArray = starsJson["data"] as? [[String: Any]] {
                print("Found \(booksArray.count) starred books in data array")
                starredBookIds = booksArray.compactMap { bookDict -> Int? in
                    if let idInt = bookDict["id"] as? Int {
                        print("Extracting book ID: \(idInt)")
                        return idInt
                    } else if let idString = bookDict["id"] as? String, let idInt = Int(idString) {
                        print("Extracting book ID from string: \(idInt)")
                        return idInt
                    } else {
                        print("Failed to extract book ID from: \(bookDict["id"] ?? "nil")")
                        return nil
                    }
                }
            }
        }
        
        print("Starred book IDs: \(starredBookIds)")
        
        // Now get detailed book info for each starred book
        var detailedBooks: [Book] = []
        
        for bookId in starredBookIds {
            do {
                guard let bookUrl = URL(string: "\(apiService.baseURL)/books/\(bookId)") else {
                    continue
                }
                
                var bookRequest = URLRequest(url: bookUrl)
                if let token = UserDefaults.standard.string(forKey: "auth_token") {
                    bookRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let (bookData, bookResponse) = try await URLSession.shared.data(for: bookRequest)
                
                guard let httpBookResponse = bookResponse as? HTTPURLResponse,
                      httpBookResponse.statusCode == 200 else {
                    print("Book detail API error for book \(bookId): \((bookResponse as? HTTPURLResponse)?.statusCode ?? -1)")
                    continue
                }
                
                if let bookJson = try JSONSerialization.jsonObject(with: bookData) as? [String: Any],
                   let bookDict = bookJson["data"] as? [String: Any] {
                    print("Book detail for \(bookId): \(bookDict)")
                    
                    guard let title = bookDict["title"] as? String else { continue }
                    
                    let views = bookDict["read_count"] as? Int ?? bookDict["view_count"] as? Int ?? 0
                    let likes = bookDict["like_count"] as? Int ?? bookDict["likes"] as? Int ?? 0
                    
                    print("Book '\(title)' detailed stats - views: \(views), likes: \(likes)")
                    
                    let book = Book(
                        id: String(bookId),
                        title: title,
                        description: bookDict["description"] as? String ?? "",
                        status: "published",
                        authorName: (bookDict["user"] as? [String: Any])?["username"] as? String ?? "Unknown",
                        chapters: bookDict["published_chapter_count"] as? Int ?? 0,
                        views: views,
                        likes: likes,
                        coverUrl: bookDict["cover_url"] as? String,
                        publishedChapterCount: bookDict["published_chapter_count"] as? Int ?? 0,
                        wordNumber: bookDict["word_number"] as? Int ?? 0
                    )
                    
                    detailedBooks.append(book)
                }
            } catch {
                print("Failed to get details for book \(bookId): \(error)")
                continue
            }
        }
        
        print("Loaded \(detailedBooks.count) detailed starred books")
        return detailedBooks
    }
    
    // MARK: - Get Ranked Books
    func getRankedBooks(rankingType: RankingType, limit: Int = 20) async throws -> [Book] {
        guard let url = URL(string: "\(apiService.baseURL)/books?sort_method=\(rankingType.rawValue)&sort_direction=desc&limit=\(limit)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let booksArray = json["data"] as? [[String: Any]] {
            
            return booksArray.compactMap { bookDict -> Book? in
                guard let title = bookDict["title"] as? String else { return nil }
                
                let bookId = bookDict["id"] as? Int ?? 0
                return Book(
                    id: bookId > 0 ? String(bookId) : UUID().uuidString,
                    title: title,
                    description: bookDict["description"] as? String ?? "",
                    status: "published",
                    authorName: bookDict["author_name"] as? String ?? "Unknown",
                    chapters: bookDict["published_chapter_count"] as? Int ?? 0,
                    views: bookDict["view_count"] as? Int ?? 0,
                    likes: bookDict["like_count"] as? Int ?? 0,
                    coverUrl: bookDict["cover_url"] as? String,
                    publishedChapterCount: bookDict["published_chapter_count"] as? Int ?? 0,
                    wordNumber: bookDict["word_number"] as? Int ?? 0
                )
            }
        }
        
        return []
    }
    
    // MARK: - Get Starred Books Count
    func getStarredBooksCount() async throws -> Int {
        let starredBooks = try await getStarredBooks()
        return starredBooks.count
    }
    
    // MARK: - Get User's Books (My Books)
    func getUserBooks() async throws -> [Book] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        // Get user ID from current user or extract from token
        var userId = "2" // Default fallback
        if let currentUser = apiService.currentUser {
            userId = currentUser.id
        }
        
        guard let url = URL(string: "\(apiService.baseURL)/books/user/\(userId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("User books API error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("User books error response: \(responseString)")
            }
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("User books API response: \(json)")
            
            // Try multiple possible response formats
            var booksArray: [[String: Any]]? = nil
            
            if let dataArray = json["data"] as? [[String: Any]] {
                booksArray = dataArray
                print("Found books in 'data' array: \(dataArray.count)")
            } else if let booksDirectArray = json["books"] as? [[String: Any]] {
                booksArray = booksDirectArray
                print("Found books in 'books' array: \(booksDirectArray.count)")
            } else if let resultArray = json["result"] as? [[String: Any]] {
                booksArray = resultArray
                print("Found books in 'result' array: \(resultArray.count)")
            } else {
                print("No books array found in response")
                print("Available keys: \(Array(json.keys))")
                print("Full response: \(json)")
            }
            
            if let booksArray = booksArray {
                return booksArray.compactMap { bookDict -> Book? in
                    print("Processing user book dict: \(bookDict)")
                    guard let title = bookDict["title"] as? String else { 
                        print("No title found, skipping user book")
                        return nil 
                    }
                    
                    let views = bookDict["views"] as? Int ?? bookDict["view_count"] as? Int ?? bookDict["read_count"] as? Int ?? 0
                    let likes = bookDict["likes"] as? Int ?? bookDict["like_count"] as? Int ?? 0
                    let status = bookDict["status"] as? String ?? "draft"
                    
                    print("User book '\(title)' - status: \(status), views: \(views), likes: \(likes)")
                    
                    return Book(
                        id: bookDict["id"] as? String ?? String(bookDict["id"] as? Int ?? 0),
                        title: title,
                        description: bookDict["description"] as? String ?? "",
                        status: status,
                        authorName: bookDict["author_name"] as? String ?? "Unknown",
                        chapters: bookDict["chapters"] as? Int ?? 0,
                        views: views,
                        likes: likes,
                        coverUrl: bookDict["cover_url"] as? String,
                        publishedChapterCount: bookDict["published_chapter_count"] as? Int ?? 0,
                        wordNumber: bookDict["word_number"] as? Int ?? 0
                    )
                }
            }
        }
        
        return []
    }
    
    // MARK: - Get Books by Category
    func getBooksByCategory(categoryId: Int) async throws -> [Book] {
        guard let url = URL(string: "\(apiService.baseURL)/books?category_id=\(categoryId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("Category books API error: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Category books error response: \(responseString)")
            }
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Category books API response: \(json)")
            let booksArray = json["books"] as? [[String: Any]] ?? json["data"] as? [[String: Any]] ?? []
            
            return booksArray.compactMap { bookDict -> Book? in
                guard let title = bookDict["title"] as? String else { return nil }
                
                return Book(
                    id: bookDict["id"] as? String ?? String(bookDict["id"] as? Int ?? 0),
                    title: title,
                    description: bookDict["description"] as? String ?? "",
                    status: "published",
                    authorName: bookDict["author_name"] as? String ?? "Unknown",
                    chapters: bookDict["chapters"] as? Int ?? 0,
                    views: bookDict["views"] as? Int ?? bookDict["read_count"] as? Int ?? 0,
                    likes: bookDict["likes"] as? Int ?? bookDict["like_count"] as? Int ?? 0,
                    coverUrl: bookDict["cover_url"] as? String,
                    publishedChapterCount: bookDict["published_chapter_count"] as? Int ?? 0,
                    wordNumber: bookDict["word_number"] as? Int ?? 0
                )
            }
        }
        
        return []
    }
}