import SwiftUI
import Foundation

// MARK: - Simple Models
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    
    init(id: String = UUID().uuidString, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
    }
}

struct Book: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let status: String
    let authorName: String
    let chapters: Int
    let views: Int
    let likes: Int
    
    init(id: String = UUID().uuidString, title: String, description: String, status: String = "draft", authorName: String, chapters: Int = 0, views: Int = 0, likes: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.authorName = authorName
        self.chapters = chapters
        self.views = views
        self.likes = likes
    }
}

// MARK: - Simple API Service
@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "http://localhost:8000/api"
    
    func login(username: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.authenticationFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Login response: \(json)")
            
            // Extract token and user info
            let token = json["token"] as? String ?? (json["data"] as? [String: Any])?["token"] as? String
            let userDict = json["user"] as? [String: Any] ?? (json["data"] as? [String: Any])?["user"] as? [String: Any] ?? [:]
            
            if let token = token {
                UserDefaults.standard.set(token, forKey: "auth_token")
                
                let user = User(
                    id: userDict["id"] as? String ?? "1",
                    username: userDict["username"] as? String ?? username,
                    email: userDict["email"] as? String ?? "\(username)@example.com"
                )
                
                isAuthenticated = true
                currentUser = user
            } else {
                throw APIError.invalidResponse
            }
        }
    }
    
    func register(username: String, email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.authenticationFailed
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Register response: \(json)")
            
            // Try to login after registration
            try await login(username: username, password: password)
        }
    }
    
    func getUserBooks() async throws -> [Book] {
        guard let token = UserDefaults.standard.string(forKey: "auth_token"),
              let userId = currentUser?.id else {
            throw APIError.notAuthenticated
        }
        
        var allBooks: [Book] = []
        
        // Fetch books for each status: 0 (draft), 1 (published), 2 (completed)
        for status in [0, 1, 2] {
            guard let url = URL(string: "\(baseURL)/books/user/\(userId)?status=\(status)") else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                continue // Skip this status if it fails
            }
            
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Books response for status \(status): \(json)")
                
                // Parse books from response
                let booksArray = json["books"] as? [[String: Any]] ?? json["data"] as? [[String: Any]] ?? []
                
                let books = booksArray.compactMap { bookDict in
                    guard let title = bookDict["title"] as? String else { return nil }
                    
                    let statusString = status == 0 ? "draft" : (status == 1 ? "published" : "completed")
                    
                    return Book(
                        id: bookDict["id"] as? String ?? UUID().uuidString,
                        title: title,
                        description: bookDict["description"] as? String ?? "",
                        status: statusString,
                        authorName: currentUser?.username ?? "Unknown",
                        chapters: bookDict["chapters"] as? Int ?? 0,
                        views: bookDict["views"] as? Int ?? 0,
                        likes: bookDict["likes"] as? Int ?? 0
                    )
                }
                
                allBooks.append(contentsOf: books)
            }
        }
        
        return allBooks
    }
    
    func createBook(title: String, description: String) async throws -> Book {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            throw APIError.notAuthenticated
        }
        
        guard let url = URL(string: "\(baseURL)/books") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = [
            "title": title,
            "description": description,
            "status": 0,
            "tags": []
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.requestFailed
        }
        
        print("Create book response status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("Create book response: \(responseString)")
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw APIError.requestFailed
        }
        
        let book = Book(
            title: title,
            description: description,
            status: "draft",
            authorName: currentUser?.username ?? "Unknown"
        )
        
        return book
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
        isAuthenticated = false
        currentUser = nil
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case authenticationFailed
    case notAuthenticated
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .authenticationFailed:
            return "Authentication failed"
        case .notAuthenticated:
            return "Not authenticated"
        case .requestFailed:
            return "Request failed"
        case .invalidResponse:
            return "Invalid response"
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @StateObject private var apiService = APIService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo
                VStack(spacing: 16) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Mythos")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Login to your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                // Login Button
                Button(action: login) {
                    HStack {
                        if apiService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Login")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(apiService.isLoading || username.isEmpty || password.isEmpty)
                .padding(.horizontal, 20)
                
                // Register Button
                Button("Don't have an account? Register") {
                    showingRegister = true
                }
                .foregroundColor(.blue)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
            }
            .alert("Login Error", isPresented: .constant(apiService.errorMessage != nil)) {
                Button("OK") { apiService.errorMessage = nil }
            } message: {
                Text(apiService.errorMessage ?? "")
            }
        }
    }
    
    private func login() {
        Task {
            do {
                try await apiService.login(username: username, password: password)
            } catch {
                apiService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @StateObject private var apiService = APIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                Button(action: register) {
                    HStack {
                        if apiService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Register")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                }
                .disabled(apiService.isLoading || !isFormValid)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && password.count >= 6
    }
    
    private func register() {
        Task {
            do {
                try await apiService.register(username: username, email: email, password: password)
                dismiss()
            } catch {
                apiService.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - My Books View
struct MyBooksView: View {
    @StateObject private var apiService = APIService.shared
    @State private var books: [Book] = []
    @State private var isLoading = false
    @State private var showingCreateBook = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading your books...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if books.isEmpty {
                    emptyStateView
                } else {
                    List(books) { book in
                        BookRowView(book: book)
                    }
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateBook = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Logout") {
                        apiService.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .task {
                await loadBooks()
            }
            .refreshable {
                await loadBooks()
            }
            .sheet(isPresented: $showingCreateBook) {
                CreateBookView { book in
                    books.append(book)
                    showingCreateBook = false
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No Books Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first book to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Create Your First Book") {
                showingCreateBook = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func loadBooks() async {
        isLoading = true
        do {
            books = try await apiService.getUserBooks()
        } catch {
            print("Failed to load books: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Book Row View
struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 80)
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authorName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(book.status.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(book.chapters) chapters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Label("\(book.views)", systemImage: "eye")
                    Label("\(book.likes)", systemImage: "heart")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Book View
struct CreateBookView: View {
    @StateObject private var apiService = APIService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    
    let onBookCreated: (Book) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Book Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Create Book") {
                        createBook()
                    }
                    .disabled(title.isEmpty || description.isEmpty || apiService.isLoading)
                }
            }
            .navigationTitle("Create Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func createBook() {
        Task {
            do {
                let book = try await apiService.createBook(title: title, description: description)
                onBookCreated(book)
            } catch {
                print("Failed to create book: \(error)")
            }
        }
    }
}

// MARK: - Main App
struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    
    var body: some View {
        Group {
            if apiService.isAuthenticated {
                MyBooksView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Check if user is already logged in
            if UserDefaults.standard.string(forKey: "auth_token") != nil {
                // Could try to validate token here
            }
        }
    }
}

// MARK: - App Entry Point
@main
struct MythosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}