import SwiftUI

// MARK: - Modern Profile View
struct ProfileView: View {
    @StateObject private var apiService = APIService.shared
    @StateObject private var bookService = BookService()
    @State private var showingSettings = false
    @State private var showingFavorites = false
    @State private var showingMyBooks = false
    @State private var starredBooksCount = 0
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Modern Profile Header
                    ModernProfileHeader(user: apiService.currentUser)
                    
                    // Stats Card - Only show starred books count
                    ModernStatCard(
                        title: "Favorites",
                        value: "\(starredBooksCount)",
                        icon: "star.fill",
                        color: .warning,
                        action: { showingFavorites = true }
                    )
                    .padding(.horizontal, 20)
                    
                    // Quick Actions
                    ModernQuickActions(
                        onMyBooks: { showingMyBooks = true },
                        onFavorites: { showingFavorites = true },
                        onSettings: { showingSettings = true }
                    )
                    
                    // Menu Items
                    ModernMenuSection(
                        onMyBooks: { showingMyBooks = true },
                        onFavorites: { showingFavorites = true },
                        onSettings: { showingSettings = true },
                        onLogout: { apiService.logout() }
                    )
                    
                    // Bottom spacing
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    colors: [Color.brandPink, Color.brandPurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await loadStarredBooksCount() }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ModernSettingsView()
        }
        .sheet(isPresented: $showingFavorites) {
            BookshelfView()
        }
        .sheet(isPresented: $showingMyBooks) {
            ModernMyBooksView()
        }
    }
    
    private func loadStarredBooksCount() async {
        do {
            starredBooksCount = try await bookService.getStarredBooksCount()
        } catch {
            starredBooksCount = 0
        }
    }
}

// MARK: - Modern Profile Components

struct ModernProfileHeader: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 20) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandPink, Color.brandPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(user?.username.prefix(1).uppercased() ?? "U")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // User Info
            VStack(spacing: 8) {
                Text(user?.username ?? "User")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                if let email = user?.email, !email.isEmpty {
                    Text(email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.top, 20)
    }
}


struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text(title)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ModernCardButtonStyle())
    }
}

struct ModernQuickActions: View {
    let onMyBooks: () -> Void
    let onFavorites: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Quick Actions")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.bottom, 16)
            
            HStack(spacing: 12) {
                ModernQuickActionCard(
                    title: "My Books",
                    icon: "book.fill",
                    color: .blue,
                    action: onMyBooks
                )
                
                ModernQuickActionCard(
                    title: "Favorites",
                    icon: "star.fill",
                    color: .warning,
                    action: onFavorites
                )
                
                ModernQuickActionCard(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: .gray,
                    action: onSettings
                )
            }
        }
    }
}

struct ModernQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ModernCardButtonStyle())
    }
}

struct ModernMenuSection: View {
    let onMyBooks: () -> Void
    let onFavorites: () -> Void
    let onSettings: () -> Void
    let onLogout: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("More Options")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.bottom, 16)
            
            VStack(spacing: 1) {
                ModernMenuRow(
                    icon: "book.stack.fill",
                    title: "My Library",
                    subtitle: "View all your books",
                    action: onMyBooks
                )
                
                ModernMenuRow(
                    icon: "clock.fill",
                    title: "Reading History",
                    subtitle: "Your reading progress",
                    action: {}
                )
                
                ModernMenuRow(
                    icon: "creditcard.fill",
                    title: "Credits",
                    subtitle: "Manage your balance",
                    action: {}
                )
                
                ModernMenuRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Feedback",
                    subtitle: "Get support",
                    action: {}
                )
                
                ModernMenuRow(
                    icon: "gearshape.fill",
                    title: "Settings",
                    subtitle: "App preferences",
                    action: onSettings
                )
                
                ModernMenuRow(
                    icon: "rectangle.portrait.and.arrow.right.fill",
                    title: "Sign Out",
                    subtitle: "",
                    isDestructive: true,
                    showChevron: false,
                    action: onLogout
                )
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ModernMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isDestructive: Bool
    let showChevron: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        isDestructive: Bool = false,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .blue)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isDestructive ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Button Style

struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Modern Settings View

struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ModernSettingsSection(title: "Appearance") {
                            ModernSettingsRow(
                                icon: "paintbrush.fill",
                                title: "Theme",
                                value: "System",
                                action: {}
                            )
                            
                            ModernSettingsRow(
                                icon: "textformat.size",
                                title: "Font Size",
                                value: "Medium",
                                action: {}
                            )
                        }
                        
                        ModernSettingsSection(title: "Reading") {
                            ModernSettingsRow(
                                icon: "book.fill",
                                title: "Auto-bookmark",
                                hasToggle: true,
                                action: {}
                            )
                            
                            ModernSettingsRow(
                                icon: "moon.fill",
                                title: "Night Mode",
                                hasToggle: true,
                                action: {}
                            )
                        }
                        
                        ModernSettingsSection(title: "Notifications") {
                            ModernSettingsRow(
                                icon: "bell.fill",
                                title: "Push Notifications",
                                hasToggle: true,
                                action: {}
                            )
                            
                            ModernSettingsRow(
                                icon: "envelope.fill",
                                title: "Email Updates",
                                hasToggle: true,
                                action: {}
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
        }
    }
}

struct ModernSettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.bottom, 12)
            
            VStack(spacing: 1) {
                content
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ModernSettingsRow: View {
    let icon: String
    let title: String
    let value: String?
    let hasToggle: Bool
    let action: () -> Void
    
    @State private var isToggled = false
    
    init(
        icon: String,
        title: String,
        value: String? = nil,
        hasToggle: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.hasToggle = hasToggle
        self.action = action
    }
    
    var body: some View {
        Button(action: hasToggle ? {} : action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.brandPink)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                Text(title)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if hasToggle {
                    Toggle("", isOn: $isToggled)
                        .labelsHidden()
                } else if let value = value {
                    Text(value)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.textSecondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern My Books View

struct ModernMyBooksView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bookService = BookService()
    @State private var userBooks: [Book] = []
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading your books...")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.textSecondary)
                    }
                } else if userBooks.isEmpty {
                    ModernEmptyBooksView()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(userBooks) { book in
                                BookCard(book: book)
                            }
                        }
                        .padding(20)
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
            .navigationTitle("My Books")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .refreshable {
                await loadUserBooks()
            }
            .onAppear {
                Task { await loadUserBooks() }
            }
        }
    }
    
    private func loadUserBooks() async {
        isLoading = true
        do {
            userBooks = try await bookService.getUserBooks()
        } catch {
            print("Failed to load user books: \(error)")
        }
        isLoading = false
    }
}

struct ModernEmptyBooksView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Books Yet")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.textPrimary)
                
                Text("Start writing your first story!")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Create Book")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemBlue))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 40)
    }
}