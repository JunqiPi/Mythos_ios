import SwiftUI

// MARK: - Ranking Detail View
struct RankingDetailView: View {
    let rankingType: RankingType
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
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                                VStack {
                                    // Ranking Badge
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                rankingColor(for: index)
                                            )
                                            .cornerRadius(8)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 4)
                                    
                                    BookCard(book: book)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(rankingType.displayName)
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
            books = try await bookService.getRankedBooks(rankingType: rankingType, limit: 50)
        } catch {
            print("Failed to load ranked books: \(error)")
        }
        isLoading = false
    }
    
    private func rankingColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .brandPurple
        }
    }
}