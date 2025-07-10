import SwiftUI
import MythosCore
import MythosNetworking

public struct MyBooksView: View {
    @StateObject private var bookService = BookService(apiClient: APIClient.shared)
    @StateObject private var authService = SimpleAuthService.shared
    
    @State private var books: [Book] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingCreateBook = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.2)
                        Text("Loading your books...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if books.isEmpty {
                    emptyStateView
                } else {
                    booksList
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateBook = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .refreshable {
                await loadBooks()
            }
            .sheet(isPresented: $showingCreateBook) {
                CreateBookView { book in
                    showingCreateBook = false
                    books.append(book)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            await loadBooks()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Books Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first book to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                showingCreateBook = true
            }) {
                Text("Create Your First Book")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 44)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private var booksList: some View {
        List(books) { book in
            BookRowView(book: book)
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadBooks() async {
        isLoading = true
        errorMessage = ""
        
        do {
            let fetchedBooks = try await bookService.getUserBooks()
            await MainActor.run {
                books = fetchedBooks
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func logout() {
        Task {
            await authService.logout()
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 12) {
            // Book Cover Placeholder
            AsyncImage(url: book.coverImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 60, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author.penName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    StatusBadge(status: book.status)
                    Spacer()
                    Text("\(book.stats.totalChapters) chapters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(book.stats.views)", systemImage: "eye")
                    Label("\(book.stats.likes)", systemImage: "heart")
                    Label("\(book.stats.comments)", systemImage: "bubble.left")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: BookStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .draft:
            return .orange
        case .published:
            return .blue
        case .completed:
            return .green
        case .onHold:
            return .yellow
        case .discontinued:
            return .red
        }
    }
}

#Preview {
    MyBooksView()
}