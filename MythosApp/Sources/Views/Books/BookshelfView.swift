import SwiftUI

// MARK: - Bookshelf View
struct BookshelfView: View {
    @StateObject private var bookService = BookService()
    @StateObject private var interactionService = InteractionService()
    @State private var books: [Book] = []
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading...")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    }
                } else if books.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        Text("Your Library is Empty")
                            .font(.title2)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Text("Go to Home and save some books!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(books) { book in
                                BookCard(book: book, onStarToggle: { bookId, isStarred in
                                    handleStarToggle(bookId: bookId, isStarred: isStarred)
                                })
                            }
                        }
                        .padding()
                    }
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
            .navigationTitle("Library")
            .refreshable {
                await loadBooks()
            }
            .onAppear {
                Task {
                    await loadBooks()
                }
            }
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        do {
            books = try await bookService.getStarredBooks()
            print("Loaded \(books.count) starred books for bookshelf")
        } catch {
            print("Failed to load starred books: \(error)")
        }
        isLoading = false
    }
    
    private func handleStarToggle(bookId: String, isStarred: Bool) {
        if isStarred {
            // If starred and not already in bookshelf, we need to fetch the book details and add it
            Task {
                // Could implement getBookDetails if needed
            }
        } else {
            // If unstarred, remove from bookshelf but don't close the detail view
            // Use a delayed removal to avoid dismissing the sheet immediately
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                books.removeAll { $0.id == bookId }
            }
        }
    }
}