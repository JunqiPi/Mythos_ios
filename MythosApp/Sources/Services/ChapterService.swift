import Foundation

// MARK: - Chapter Service
@MainActor
class ChapterService: ObservableObject {
    private let apiService = APIService.shared
    
    // MARK: - Get Book Chapters
    func getBookChapters(bookId: String) async throws -> [Chapter] {
        guard let url = URL(string: "\(apiService.baseURL)/chapters/book/\(bookId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("Loading chapters for book ID: \(bookId)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        
        print("Chapters API response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let chaptersArray = json["data"] as? [[String: Any]] ?? json["chapters"] as? [[String: Any]] {
            
            print("Found \(chaptersArray.count) chapters")
            
            let chapters = chaptersArray.compactMap { chapterData -> Chapter? in
                // Enhanced ID parsing
                let id: String
                if let idInt = chapterData["id"] as? Int {
                    id = String(idInt)
                } else if let idString = chapterData["id"] as? String {
                    id = idString
                } else {
                    id = "0"
                }
                
                let bookId: String
                if let bookIdInt = chapterData["book_id"] as? Int {
                    bookId = String(bookIdInt)
                } else if let bookIdString = chapterData["book_id"] as? String {
                    bookId = bookIdString
                } else {
                    bookId = "0"
                }
                
                guard let title = chapterData["title"] as? String,
                      let chapterNumber = chapterData["chapter_number"] as? Int else {
                    return nil
                }
                
                return Chapter(
                    id: id,
                    bookId: bookId,
                    chapterNumber: chapterNumber,
                    title: title,
                    status: chapterData["status"] as? Int ?? 1,
                    isLocked: chapterData["is_locked"] as? Bool ?? false,
                    creditPrice: chapterData["credit_price"] as? Int ?? 0,
                    wordCount: chapterData["word_count"] as? Int ?? 0,
                    readingTimeMinutes: chapterData["reading_time_minutes"] as? Int ?? 0,
                    publishedAt: chapterData["published_at"] as? String,
                    nextChapterId: chapterData["next_chapter_id"] as? String,
                    prevChapterId: chapterData["prev_chapter_id"] as? String
                )
            }
            
            print("Loaded \(chapters.count) chapters")
            return chapters
        }
        
        return []
    }
    
    // MARK: - Get Chapter Content
    func getChapterContent(chapterId: String) async throws -> ChapterContent {
        guard let url = URL(string: "\(apiService.baseURL)/chapters/\(chapterId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("=== CHAPTER CONTENT DEBUG ===")
        print("Fetching chapter content for ID: \(chapterId)")
        print("Request URL: \(url.absoluteString)")
        print("Authorization header: \(request.value(forHTTPHeaderField: "Authorization") ?? "none")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Failed to get HTTP response")
            throw APIError.requestFailed
        }
        
        print("Chapter content API response status: \(httpResponse.statusCode)")
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 200 {
            print("❌ API returned error status: \(httpResponse.statusCode)")
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response body: \(errorString)")
            }
            throw APIError.requestFailed
        }
        
        print("✅ Got successful response, data length: \(data.count) bytes")
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✅ Successfully parsed JSON")
            print("JSON root keys: \(Array(json.keys).sorted())")
            
            // Check different possible data locations
            print("Checking json['data']: \(json["data"] != nil ? "EXISTS" : "nil")")
            print("Checking json['chapter']: \(json["chapter"] != nil ? "EXISTS" : "nil")")
            
            let chapterData = json["data"] as? [String: Any] ?? json["chapter"] as? [String: Any] ?? json
            
            print("📖 Chapter data source: \(json["data"] != nil ? "json[data]" : json["chapter"] != nil ? "json[chapter]" : "json root")")
            print("Chapter data keys: \(Array(chapterData.keys).sorted())")
            
            if !chapterData.isEmpty {
                print("✅ Found chapter data, parsing...")
                
                // Enhanced ID parsing
                let id: String
                if let idInt = chapterData["id"] as? Int {
                    id = String(idInt)
                } else if let idString = chapterData["id"] as? String {
                    id = idString
                } else {
                    id = chapterId
                }
                
                let bookId: String
                if let bookIdInt = chapterData["book_id"] as? Int {
                    bookId = String(bookIdInt)
                } else if let bookIdString = chapterData["book_id"] as? String {
                    bookId = bookIdString
                } else {
                    bookId = "0"
                }
                
                // Extract content from multiple possible fields
                print("🔍 CONTENT EXTRACTION DEBUG:")
                print("json['content'] type: \(type(of: json["content"])), exists: \(json["content"] != nil)")
                print("chapterData['content'] type: \(type(of: chapterData["content"])), exists: \(chapterData["content"] != nil)")
                print("chapterData['content_text'] type: \(type(of: chapterData["content_text"])), exists: \(chapterData["content_text"] != nil)")
                print("chapterData['content_html'] type: \(type(of: chapterData["content_html"])), exists: \(chapterData["content_html"] != nil)")
                
                // The API might return content at the root level or inside chapter data
                let content = json["content"] as? String ?? 
                             chapterData["content"] as? String ?? 
                             chapterData["content_text"] as? String ?? 
                             chapterData["content_html"] as? String
                
                print("📝 Final extracted content length: \(content?.count ?? 0)")
                if let content = content, !content.isEmpty {
                    print("✅ Content found! Preview: \(String(content.prefix(100)))...")
                } else {
                    print("❌ NO CONTENT FOUND!")
                    print("🔍 Debugging all possible content fields:")
                    print("  - json['content']: \(json["content"] ?? "nil")")
                    print("  - chapterData['content']: \(chapterData["content"] ?? "nil")")
                    print("  - chapterData['content_text']: \(chapterData["content_text"] ?? "nil")")
                    print("  - chapterData['content_html']: \(chapterData["content_html"] ?? "nil")")
                    print("📋 All root JSON keys: \(Array(json.keys).sorted())")
                    print("📋 All chapterData keys: \(Array(chapterData.keys).sorted())")
                }
                
                // Parse chapter detail
                let chapterDetail = ChapterDetail(
                    id: id,
                    bookId: bookId,
                    chapterNumber: chapterData["chapter_number"] as? Int ?? 1,
                    title: chapterData["title"] as? String ?? "Untitled",
                    content: content,
                    contentHtml: json["content_html"] as? String ?? chapterData["content_html"] as? String,
                    contentText: json["content_text"] as? String ?? chapterData["content_text"] as? String ?? content,
                    wordCount: chapterData["word_count"] as? Int ?? 0,
                    status: chapterData["status"] as? Int ?? 1,
                    isLocked: chapterData["is_locked"] as? Bool ?? false,
                    creditPrice: chapterData["credit_price"] as? Int ?? 0,
                    publishedAt: chapterData["published_at"] as? String,
                    book: nil, // Can add book info parsing if needed
                    nextChapter: nil, // Can add navigation parsing if needed
                    prevChapter: nil
                )
                
                let hasFullAccess = json["hasFullAccess"] as? Bool ?? json["has_full_access"] as? Bool ?? true
                let unlockReason = json["unlockReason"] as? String ?? json["unlock_reason"] as? String
                
                let chapterContent = ChapterContent(
                    chapter: chapterDetail,
                    hasFullAccess: hasFullAccess,
                    unlockReason: unlockReason
                )
                
                print("🎯 FINAL RESULT:")
                print("  - Chapter ID: \(chapterDetail.id)")
                print("  - Chapter Title: \(chapterDetail.title)")
                print("  - Content length: \(chapterDetail.content?.count ?? 0)")
                print("  - ContentText length: \(chapterDetail.contentText?.count ?? 0)")
                print("  - ContentHtml length: \(chapterDetail.contentHtml?.count ?? 0)")
                print("  - Has full access: \(hasFullAccess)")
                print("  - Unlock reason: \(unlockReason ?? "none")")
                print("=== END CHAPTER CONTENT DEBUG ===")
                
                return chapterContent
            } else {
                print("❌ Chapter data is empty or invalid")
            }
        } else {
            print("❌ Failed to parse JSON response")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Raw response: \(responseString)")
            }
        }
        
        print("=== CHAPTER CONTENT DEBUG FAILED ===")
        throw APIError.invalidResponse
    }
}