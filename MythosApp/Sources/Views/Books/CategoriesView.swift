import SwiftUI

// MARK: - Categories View
struct CategoriesView: View {
    @State private var categories: [BookCategory] = []
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sampleCategories) { category in
                                CategoryCard(category: category)
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
            .navigationTitle("Categories")
            .onAppear {
                loadCategories()
            }
        }
    }
    
    private func loadCategories() {
        // TODO: Implement API call
        categories = sampleCategories
    }
    
    private var sampleCategories: [BookCategory] {
        [
            BookCategory(id: 1, name: "都市", description: "现代都市生活", icon: "building.2"),
            BookCategory(id: 2, name: "玄幻", description: "奇幻冒险", icon: "sparkles"),
            BookCategory(id: 3, name: "武侠", description: "江湖恩仇", icon: "figure.fencing"),
            BookCategory(id: 4, name: "言情", description: "浪漫爱情", icon: "heart"),
            BookCategory(id: 5, name: "科幻", description: "未来世界", icon: "globe.central.south.asia"),
            BookCategory(id: 6, name: "历史", description: "历史传奇", icon: "scroll")
        ]
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: BookCategory
    @State private var showingCategoryBooks = false
    
    var body: some View {
        Button(action: {
            showingCategoryBooks = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 30))
                    .foregroundColor(.brandPink)
                
                Text(category.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
        .sheet(isPresented: $showingCategoryBooks) {
            CategoryBooksView(category: category)
        }
    }
}