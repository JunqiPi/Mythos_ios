import SwiftUI

// MARK: - Category Books View
struct CategoryBooksView: View {
    let category: BookCategory
    @StateObject private var bookService = BookService()
    @State private var books: [Book] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if books.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: category.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("暂无\(category.name)类书籍")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(books) { book in
                                BookCard(book: book)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(category.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            })
        }
        .onAppear {
            Task {
                await loadBooks()
            }
        }
    }
    
    private func loadBooks() async {
        isLoading = true
        do {
            books = try await bookService.getBooksByCategory(categoryId: category.id)
            print("Loaded \(books.count) books for category \(category.name)")
        } catch {
            print("Failed to load books for category \(category.name): \(error)")
        }
        isLoading = false
    }
}