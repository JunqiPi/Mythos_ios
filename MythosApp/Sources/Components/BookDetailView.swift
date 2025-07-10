import SwiftUI

// MARK: - Chapter Identifier for Sheet Presentation
struct ChapterIdentifier: Identifiable {
    let id: String
}

// MARK: - Book Detail View
struct BookDetailView: View {
    let book: Book
    let onStarToggle: ((String, Bool) -> Void)?
    @StateObject private var chapterService = ChapterService()
    @StateObject private var interactionService = InteractionService()
    @State private var chapters: [Chapter] = []
    @State private var isLoading = false
    @State private var selectedChapterId: String?
    @State private var isLiked = false
    @State private var isStarred = false
    @State private var currentLikes: Int
    @Environment(\.dismiss) private var dismiss
    
    init(book: Book, onStarToggle: ((String, Bool) -> Void)? = nil) {
        self.book = book
        self.onStarToggle = onStarToggle
        self._currentLikes = State(initialValue: book.likes)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    // Book Header
                    HStack(alignment: .top, spacing: 16) {
                        // Book Cover
                        AsyncImage(url: book.coverUrl != nil ? URL(string: book.coverUrl!) : nil) { image in
                            image
                                .resizable()
                                .aspectRatio(3/4, contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color.brandPink.opacity(0.3), Color.brandPurple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .aspectRatio(3/4, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        }
                        .frame(width: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(book.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("作者：\(book.authorName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(book.statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor)
                                .cornerRadius(8)
                            
                            // Stats
                            HStack(spacing: 16) {
                                StatItem(icon: "eye", value: "\(book.views)", label: "阅读")
                                StatItem(icon: "heart.fill", value: "\(currentLikes)", label: "喜欢")
                                StatItem(icon: "star.fill", value: "\(book.chapters)", label: "章节")
                            }
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Action Buttons (Like and Star)
                    HStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await toggleLike()
                            }
                        }) {
                            HStack {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundColor(isLiked ? .brandPink : .textSecondary)
                                Text(isLiked ? "Liked" : "Like")
                                    .foregroundColor(isLiked ? .brandPink : .textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.surfaceElevated)
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(isLiked ? Color.brandPink.opacity(0.3) : Color.border, lineWidth: 1)
                            )
                        }
                        
                        Button(action: {
                            Task {
                                await toggleStar()
                            }
                        }) {
                            HStack {
                                Image(systemName: isStarred ? "star.fill" : "star")
                                    .foregroundColor(isStarred ? .warning : .textSecondary)
                                Text(isStarred ? "Saved" : "Save")
                                    .foregroundColor(isStarred ? .warning : .textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.surfaceElevated)
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(isStarred ? Color.warning.opacity(0.3) : Color.border, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Text(book.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal)
                    
                    // Chapters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Chapters")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Spacer()
                            
                            if !chapters.isEmpty {
                                Button("Start Reading") {
                                    startReading()
                                }
                                .primaryButton()
                            }
                        }
                        
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView("加载章节中...")
                                Spacer()
                            }
                            .padding()
                        } else if chapters.isEmpty {
                            Text("暂无章节")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(chapters) { chapter in
                                    ChapterRow(chapter: chapter) {
                                        print("📖 Chapter tapped: \(chapter.title) (ID: \(chapter.id))")
                                        selectedChapterId = chapter.id
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.brandPink, Color.brandPurple, Color.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .overlay(alignment: .topLeading) {
                Button("Close") {
                    dismiss()
                }
                .padding()
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
        }
        .sheet(item: Binding<ChapterIdentifier?>(
            get: { selectedChapterId.map(ChapterIdentifier.init) },
            set: { selectedChapterId = $0?.id }
        )) { chapterIdentifier in
            ChapterReaderView(chapterId: chapterIdentifier.id)
                .onAppear {
                    print("📱 Presenting ChapterReaderView with chapterId: \(chapterIdentifier.id)")
                }
        }
        .onAppear {
            Task {
                await loadChapters()
                await loadInteractionStatus()
            }
        }
    }
    
    private var statusColor: Color {
        switch book.status {
        case "draft": return .orange
        case "published": return .green
        case "completed": return .blue
        default: return .gray
        }
    }
    
    private func loadChapters() async {
        isLoading = true
        do {
            chapters = try await chapterService.getBookChapters(bookId: book.id)
        } catch {
            print("Failed to load chapters: \(error)")
        }
        isLoading = false
    }
    
    private func loadInteractionStatus() async {
        do {
            let status = try await interactionService.getBookInteractionStatus(bookId: book.id)
            isLiked = status.liked
            isStarred = status.starred
        } catch {
            print("Failed to load interaction status for book \(book.id): \(error)")
        }
    }
    
    private func toggleLike() async {
        do {
            let newLikedStatus = try await interactionService.toggleBookLike(bookId: book.id)
            isLiked = newLikedStatus
            
            // Update like count
            currentLikes += newLikedStatus ? 1 : -1
        } catch {
            print("Failed to toggle like: \(error)")
        }
    }
    
    private func toggleStar() async {
        do {
            let newStarredStatus = try await interactionService.toggleBookStar(bookId: book.id)
            isStarred = newStarredStatus
            
            // Call the callback if provided
            onStarToggle?(book.id, newStarredStatus)
            
            // Send notification for real-time updates across views
            NotificationCenter.default.post(
                name: NSNotification.Name("BookStarToggled"),
                object: nil,
                userInfo: ["bookId": book.id, "isStarred": newStarredStatus]
            )
            
            print("Book \(book.title) star toggled: \(newStarredStatus)")
        } catch {
            print("Failed to toggle star: \(error)")
        }
    }
    
    private func startReading() {
        print("🚀 Start Reading button tapped")
        // Try to find the first chapter, or create a dummy one for testing
        if let firstChapter = chapters.first {
            print("📖 Starting with first chapter: \(firstChapter.title) (ID: \(firstChapter.id))")
            selectedChapterId = firstChapter.id
        } else {
            print("⚠️ No chapters found, using dummy chapter ID")
            // For testing - use a dummy chapter ID
            // You can replace this with actual logic to handle books without chapters
            selectedChapterId = "1"
        }
        print("🎯 selectedChapterId set to: \(selectedChapterId ?? "nil")")
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}