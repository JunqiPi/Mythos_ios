# Mythos iOS 快速开始指南

这个指南将帮助您快速上手Mythos iOS框架的开发。

## 🚀 快速开始

### 1. 创建新功能

假设我们要创建一个书籍列表功能：

```swift
// Sources/MythosUI/Features/Books/BookListFeature.swift
import ComposableArchitecture
import MythosCore
import MythosNetworking

public struct BookListFeature: Reducer {
    public struct State: Equatable {
        public var books: [Book] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var searchQuery: String = ""
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case booksResponse(Result<[Book], APIError>)
        case bookTapped(Book.ID)
        case refreshTapped
    }
    
    @Dependency(\.bookService) var bookService
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let books = try await bookService.getAllBooks()
                        await send(.booksResponse(.success(books)))
                    } catch let error as APIError {
                        await send(.booksResponse(.failure(error)))
                    }
                }
                
            case .searchQueryChanged(let query):
                state.searchQuery = query
                // 实现搜索防抖
                return .none
                
            case .booksResponse(.success(let books)):
                state.books = books
                state.isLoading = false
                state.errorMessage = nil
                return .none
                
            case .booksResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .bookTapped(let bookId):
                // 导航到书籍详情
                return .none
                
            case .refreshTapped:
                state.isLoading = true
                return .send(.onAppear)
            }
        }
    }
}
```

### 2. 创建对应的视图

```swift
// Sources/MythosUI/Features/Books/BookListView.swift
import SwiftUI
import ComposableArchitecture
import MythosCore

public struct BookListView: View {
    let store: StoreOf<BookListFeature>
    
    public init(store: StoreOf<BookListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack {
                    // 搜索栏
                    SearchBar(
                        text: viewStore.binding(
                            get: \.searchQuery,
                            send: BookListFeature.Action.searchQueryChanged
                        )
                    )
                    
                    // 书籍列表
                    if viewStore.isLoading {
                        ProgressView("加载中...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = viewStore.errorMessage {
                        ErrorView(
                            message: errorMessage,
                            retryAction: { viewStore.send(.refreshTapped) }
                        )
                    } else {
                        BookGrid(
                            books: viewStore.books,
                            onBookTapped: { bookId in
                                viewStore.send(.bookTapped(bookId))
                            }
                        )
                    }
                }
                .navigationTitle("书籍")
                .navigationBarTitleDisplayMode(.large)
                .refreshable {
                    viewStore.send(.refreshTapped)
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: - 支持组件

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索书籍...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("重试", action: retryAction)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct BookGrid: View {
    let books: [Book]
    let onBookTapped: (Book.ID) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(books) { book in
                    BookCard(book: book) {
                        onBookTapped(book.id)
                    }
                }
            }
            .padding()
        }
    }
}

struct BookCard: View {
    let book: Book
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // 书籍封面
                AsyncImage(url: book.coverImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(2/3, contentMode: .fill)
                        .overlay(
                            Image(systemName: "book")
                                .foregroundColor(.gray)
                        )
                }
                .clipped()
                .cornerRadius(8)
                
                // 书籍信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.author.penName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        
                        Text(String(format: "%.1f", book.stats.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}
```

### 3. 创建服务层

```swift
// Sources/MythosNetworking/Services/BookService.swift
import Foundation
import MythosCore
import Logging

@MainActor
public final class BookService: @unchecked Sendable {
    private let apiClient: APIClient
    private let logger: Logger
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.logger = Logger(label: "com.mythos.books")
    }
    
    // MARK: - 获取所有书籍
    public func getAllBooks(
        page: Int = 1,
        limit: Int = 20,
        genre: String? = nil
    ) async throws -> [Book] {
        logger.info("Fetching books - page: \(page), limit: \(limit)")
        
        var parameters: [String: Any] = [
            "page": page,
            "limit": limit
        ]
        
        if let genre = genre {
            parameters["genre"] = genre
        }
        
        let response: BookListResponse = try await apiClient.get(
            .books,
            parameters: parameters
        )
        
        logger.info("Successfully fetched \(response.books.count) books")
        return response.books
    }
    
    // MARK: - 获取书籍详情
    public func getBook(id: String) async throws -> Book {
        logger.info("Fetching book details for ID: \(id)")
        
        let book: Book = try await apiClient.get(.book(bookId: id))
        
        logger.info("Successfully fetched book: \(book.title)")
        return book
    }
    
    // MARK: - 搜索书籍
    public func searchBooks(
        query: String,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> [Book] {
        logger.info("Searching books with query: \(query)")
        
        let parameters: [String: Any] = [
            "q": query,
            "page": page,
            "limit": limit
        ]
        
        let response: BookListResponse = try await apiClient.get(
            .searchBooks,
            parameters: parameters
        )
        
        logger.info("Search returned \(response.books.count) results")
        return response.books
    }
    
    // MARK: - 获取推荐书籍
    public func getFeaturedBooks() async throws -> [Book] {
        logger.info("Fetching featured books")
        
        let response: BookListResponse = try await apiClient.get(.featuredBooks)
        
        logger.info("Successfully fetched \(response.books.count) featured books")
        return response.books
    }
}

// MARK: - Response Models
public struct BookListResponse: Codable {
    public let books: [Book]
    public let totalCount: Int
    public let page: Int
    public let totalPages: Int
    
    public init(books: [Book], totalCount: Int, page: Int, totalPages: Int) {
        self.books = books
        self.totalCount = totalCount
        self.page = page
        self.totalPages = totalPages
    }
}
```

### 4. 注册依赖

```swift
// 在App启动时注册服务
extension DependencyValues {
    public var bookService: BookService {
        get { self[BookServiceKey.self] }
        set { self[BookServiceKey.self] = newValue }
    }
}

private enum BookServiceKey: DependencyKey {
    static let liveValue = BookService(apiClient: APIClient.shared)
    static let testValue = BookService(apiClient: MockAPIClient())
}
```

### 5. 在主应用中使用

```swift
// MythosApp/Sources/Features/MainTabFeature.swift
public struct MainTabFeature: Reducer {
    public struct State: Equatable {
        public var selectedTab: Tab = .discover
        public var bookListState: BookListFeature.State = .init()
        // 其他tab状态...
        
        public init() {}
    }
    
    public enum Action: Equatable {
        case tabSelected(Tab)
        case bookList(BookListFeature.Action)
        // 其他tab actions...
    }
    
    public enum Tab: String, CaseIterable {
        case discover = "发现"
        case library = "书架"
        case reading = "阅读"
        case profile = "我的"
    }
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.bookListState, action: /Action.bookList) {
            BookListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none
                
            case .bookList:
                return .none
            }
        }
    }
}

// 对应的View
public struct MainTabView: View {
    let store: StoreOf<MainTabFeature>
    
    public var body: some View {
        WithViewStore(store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(send: MainTabFeature.Action.tabSelected)) {
                BookListView(
                    store: store.scope(
                        state: \.bookListState,
                        action: MainTabFeature.Action.bookList
                    )
                )
                .tabItem {
                    Image(systemName: "book")
                    Text("发现")
                }
                .tag(MainTabFeature.Tab.discover)
                
                // 其他标签页...
            }
        }
    }
}
```

## 🧪 测试示例

```swift
// Tests/MythosUITests/BookListFeatureTests.swift
import XCTest
import ComposableArchitecture
import MythosCore
import MythosUI

@MainActor
final class BookListFeatureTests: XCTestCase {
    
    func testBookListLoading() async {
        let store = TestStore(initialState: BookListFeature.State()) {
            BookListFeature()
        } withDependencies: {
            $0.bookService = MockBookService()
        }
        
        await store.send(.onAppear) {
            $0.isLoading = true
        }
        
        let mockBooks = [Book.mock1, Book.mock2]
        await store.receive(.booksResponse(.success(mockBooks))) {
            $0.books = mockBooks
            $0.isLoading = false
            $0.errorMessage = nil
        }
    }
    
    func testSearchQueryUpdate() async {
        let store = TestStore(initialState: BookListFeature.State()) {
            BookListFeature()
        }
        
        await store.send(.searchQueryChanged("Swift")) {
            $0.searchQuery = "Swift"
        }
    }
}

// Mock数据
extension Book {
    static let mock1 = Book(
        id: "1",
        title: "Swift Programming",
        description: "Learn Swift",
        author: Author.mock,
        genre: .sciFi,
        status: .published,
        stats: BookStats(),
        pricing: BookPricing(model: .free),
        metadata: BookMetadata(),
        createdAt: Date(),
        updatedAt: Date()
    )
}
```

## 📱 运行应用

1. **在Xcode中打开**：
```bash
open mythos_ios/Package.swift
```

2. **选择MythosApp作为运行目标**

3. **选择iOS模拟器**

4. **点击运行按钮**

## 🎯 最佳实践

### 1. 状态管理
- 使用TCA进行状态管理
- 保持State结构简单
- 使用计算属性处理派生状态

### 2. 网络请求
- 所有网络请求都通过Service层
- 使用async/await处理异步操作
- 正确处理错误状态

### 3. UI组件
- 创建可重用的组件
- 使用SwiftUI的最新特性
- 保持视图简洁

### 4. 测试
- 为每个Feature编写测试
- 使用Mock依赖
- 测试边界情况

这个框架提供了完整的移动端开发解决方案，具有良好的可扩展性和维护性。 