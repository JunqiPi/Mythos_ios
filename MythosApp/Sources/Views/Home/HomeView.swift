import SwiftUI

// MARK: - Home View
struct HomeView: View {
    @StateObject private var bookService = BookService()
    @State private var featuredBooks: [Book] = []
    @State private var popularBooks: [Book] = []
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Ranking Buttons - Enhanced with better spacing and styling
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(RankingType.allCases, id: \.self) { ranking in
                                RankingCard(rankingType: ranking)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                    }
                    
                    // Popular Books Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Popular Books")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .padding(.horizontal)
                        
                        if isLoading {
                            ProgressView("Loading...")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(popularBooks) { book in
                                    BookCard(book: book)
                                }
                            }
                            .padding(.horizontal)
                        }
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
            .navigationTitle("Home")
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
            popularBooks = try await bookService.getAllBooks()
        } catch {
            print("Failed to load books: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Ranking Card
struct RankingCard: View {
    let rankingType: RankingType
    @State private var showingRanking = false
    
    var body: some View {
        Button(action: {
            showingRanking = true
        }) {
            VStack(spacing: 8) {
                Image(systemName: rankingType.icon)
                    .font(.title2)
                    .foregroundColor(.brandPink)
                
                Text(rankingType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 88, height: 88)
            .cardStyle()
            .modernTapScale()
            .shadow(color: .shadowMedium, radius: 12, x: 0, y: 6)
        }
        .sheet(isPresented: $showingRanking) {
            RankingDetailView(rankingType: rankingType)
        }
    }
}