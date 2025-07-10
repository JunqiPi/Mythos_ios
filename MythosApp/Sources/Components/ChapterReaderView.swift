import SwiftUI

// MARK: - Modern Chapter Reader View
struct ChapterReaderView: View {
    let chapterId: String
    @StateObject private var chapterService = ChapterService()
    @State private var chapterContent: ChapterContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var fontSize: CGFloat = 18
    @State private var isDarkMode = false
    @State private var showSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Keep reading area with proper contrast
                (isDarkMode ? Color.black : Color.white)
                    .ignoresSafeArea()
                
                if isLoading {
                    ModernLoadingView()
                } else if let errorMessage = errorMessage {
                    ModernErrorView(errorMessage: errorMessage) {
                        Task { await loadChapterContent() }
                    }
                } else if let content = chapterContent {
                    ModernReaderContent(
                        content: content,
                        fontSize: fontSize,
                        isDarkMode: isDarkMode
                    )
                }
                
                // Modern floating toolbar
                VStack {
                    ModernReaderToolbar(
                        isDarkMode: isDarkMode,
                        showSettings: $showSettings,
                        onBack: { dismiss() }
                    )
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ModernReaderSettings(
                fontSize: $fontSize,
                isDarkMode: $isDarkMode
            )
        }
        .onAppear {
            Task { await loadChapterContent() }
        }
    }
    
    private func loadChapterContent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            chapterContent = try await chapterService.getChapterContent(chapterId: chapterId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Modern Reader Components

struct ModernReaderToolbar: View {
    let isDarkMode: Bool
    @Binding var showSettings: Bool
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Button(action: { showSettings = true }) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : .black)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}

struct ModernReaderContent: View {
    let content: ChapterContent
    let fontSize: CGFloat
    let isDarkMode: Bool
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                ModernChapterHeader(content: content, isDarkMode: isDarkMode)
                
                // Content
                if content.hasFullAccess {
                    ModernTextContent(
                        content: content,
                        fontSize: fontSize,
                        isDarkMode: isDarkMode
                    )
                } else {
                    ModernLockedContent(content: content, isDarkMode: isDarkMode)
                }
                
                // Navigation
                ModernChapterNavigation(content: content, isDarkMode: isDarkMode)
                
                // Bottom padding
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 100)
            }
        }
    }
}

struct ModernChapterHeader: View {
    let content: ChapterContent
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: 120)
            
            VStack(spacing: 16) {
                // Chapter number
                Text("Chapter \(content.chapter.chapterNumber)")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                
                // Chapter title
                Text(content.chapter.title)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Metadata
                if content.chapter.wordCount > 0 {
                    HStack(spacing: 16) {
                        MetadataChip(
                            icon: "doc.text",
                            text: "\(content.chapter.wordCount) words",
                            isDarkMode: isDarkMode
                        )
                        
                        MetadataChip(
                            icon: "clock",
                            text: "~\(content.chapter.wordCount / 200) min read",
                            isDarkMode: isDarkMode
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
}

struct MetadataChip: View {
    let icon: String
    let text: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.8))
        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
    }
}

struct ModernTextContent: View {
    let content: ChapterContent
    let fontSize: CGFloat
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            if let contentText = content.chapter.contentText {
                ContentText(text: contentText, fontSize: fontSize, isDarkMode: isDarkMode)
            } else if let contentHtml = content.chapter.contentHtml {
                ContentText(
                    text: contentHtml.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression),
                    fontSize: fontSize,
                    isDarkMode: isDarkMode
                )
            } else if let textContent = content.chapter.content {
                ContentText(text: textContent, fontSize: fontSize, isDarkMode: isDarkMode)
            } else {
                ModernEmptyContent(isDarkMode: isDarkMode)
            }
        }
        .background(Color.white.opacity(0.95))
        .cornerRadius(16)
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ContentText: View {
    let text: String
    let fontSize: CGFloat
    let isDarkMode: Bool
    
    var body: some View {
        Text(text)
            .font(.system(size: fontSize, design: .rounded))
            .lineSpacing(fontSize * 0.6)
            .foregroundColor(isDarkMode ? Color(.systemGray6) : Color.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ModernEmptyContent: View {
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            Text("No Content Available")
                .font(.system(.title2, design: .rounded, weight: .medium))
                .foregroundColor(isDarkMode ? .white : .black)
            
            Text("This chapter appears to be empty.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 80)
    }
}

struct ModernLockedContent: View {
    let content: ChapterContent
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Premium Content")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                if let reason = content.unlockReason {
                    Text(reason)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            Button(action: {
                // TODO: Implement unlock functionality
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .medium))
                    Text("Unlock Chapter")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Text("(\(content.chapter.creditPrice) credits)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemBlue))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 60)
    }
}

struct ModernChapterNavigation: View {
    let content: ChapterContent
    let isDarkMode: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Divider()
                .padding(.horizontal, 40)
            
            HStack(spacing: 20) {
                if let prevChapter = content.chapter.prevChapter {
                    NavigationButton(
                        title: "Previous",
                        icon: "chevron.left",
                        isPrimary: false,
                        isDarkMode: isDarkMode
                    ) {
                        // TODO: Navigate to previous chapter
                    }
                }
                
                Spacer()
                
                if let nextChapter = content.chapter.nextChapter {
                    NavigationButton(
                        title: "Next",
                        icon: "chevron.right",
                        isPrimary: true,
                        isDarkMode: isDarkMode
                    ) {
                        // TODO: Navigate to next chapter
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
    }
}

struct NavigationButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let isDarkMode: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if icon == "chevron.left" {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                
                if icon == "chevron.right" {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .foregroundColor(isPrimary ? .white : (isDarkMode ? .white : .black))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isPrimary {
                        Color(.systemBlue)
                    } else {
                        Color.clear
                    }
                })
                .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isPrimary ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Modern Loading & Error Views

struct ModernLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading chapter...")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModernErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.orange)
            
            VStack(spacing: 12) {
                Text("Something went wrong")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                
                Text(errorMessage)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Try Again")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemBlue))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Reader Settings

struct ModernReaderSettings: View {
    @Binding var fontSize: CGFloat
    @Binding var isDarkMode: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 20) {
                    Text("Reading Settings")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    
                    // Font size
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Size")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        
                        HStack {
                            Text("A")
                                .font(.system(size: 14))
                            
                            Slider(value: $fontSize, in: 14...24, step: 1)
                            
                            Text("A")
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        Text("Preview text at \(Int(fontSize))pt")
                            .font(.system(size: fontSize, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 8)
                    }
                    
                    // Dark mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Appearance")
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                        
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .font(.system(.body, design: .rounded))
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [Color.brandPink, Color.brandPurple, Color.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
            .overlay(
                VStack {
                    HStack {
                        Spacer()
                        Button("Done") {
                            dismiss()
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    Spacer()
                }
            )
        }
    }
}