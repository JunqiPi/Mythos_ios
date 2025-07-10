import SwiftUI

// MARK: - Modern Book Card Component
struct BookCard: View {
    let book: Book
    let onStarToggle: ((String, Bool) -> Void)?
    @State private var showingBookDetail = false
    @State private var isLiked = false
    @State private var isStarred = false
    @State private var isPressed = false
    
    init(book: Book, onStarToggle: ((String, Bool) -> Void)? = nil) {
        self.book = book
        self.onStarToggle = onStarToggle
    }
    
    var body: some View {
        Button(action: {
            showingBookDetail = true
        }) {
            VStack(spacing: 0) {
                // Modern Cover with Overlay
                ZStack {
                    AsyncImage(url: book.coverUrl != nil ? URL(string: book.coverUrl!) : nil) { image in
                        image
                            .resizable()
                            .aspectRatio(3/4, contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.brandPink.opacity(0.1), Color.brandPurple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(.textTertiary)
                                    Text("No Cover")
                                        .font(.caption2)
                                        .foregroundColor(.textTertiary)
                                }
                            )
                    }
                    .frame(height: 160)
                    .clipped()
                    
                    // Status badge only
                    VStack {
                        Spacer()
                        HStack {
                            StatusBadge(status: book.status)
                            Spacer()
                        }
                    }
                    .padding(8)
                }
                
                // Modern info section
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .lineLimit(2)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.authorName)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    // Modern stats
                    HStack(spacing: 12) {
                        StatView(icon: "eye.fill", value: book.views, color: .brandPurple)
                        StatView(icon: "heart.fill", value: book.likes, color: .brandPink)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(CardButtonStyle(isPressed: $isPressed))
        .cardStyle()
        .shadow(
            color: .shadowMedium,
            radius: isPressed ? 2 : 8,
            x: 0,
            y: isPressed ? 1 : 4
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .sheet(isPresented: $showingBookDetail) {
            BookDetailView(book: book, onStarToggle: onStarToggle)
        }
    }
}


// MARK: - Modern Status Badge
struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusText)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(statusColor)
            )
            .shadow(color: statusColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private var statusText: String {
        switch status {
        case "draft": return "Draft"
        case "published": return "Live"
        case "completed": return "Complete"
        default: return "New"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case "draft": return .warning
        case "published": return .success
        case "completed": return .brandPurple
        default: return .brandPurple
        }
    }
}

// MARK: - Modern Stat View
struct StatView: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(color)
            
            Text(formatNumber(value))
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundColor(.gray)
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Modern Card Button Style
struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in
                isPressed = pressed
            }
    }
}