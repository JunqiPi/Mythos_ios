import SwiftUI

// MARK: - Chapter Row
struct ChapterRow: View {
    let chapter: Chapter
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chapter \(chapter.chapterNumber)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(chapter.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        if chapter.wordCount > 0 {
                            Text("\(chapter.wordCount) words")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if chapter.readingTimeMinutes > 0 {
                            Text("\(chapter.readingTimeMinutes) min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if chapter.isLocked {
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                Text("\(chapter.creditPrice) credits")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if chapter.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    statusBadge
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusBadge: some View {
        Group {
            switch chapter.status {
            case 0:
                Text("Draft")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange)
                    .cornerRadius(4)
            case 1:
                Text("Published")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            default:
                EmptyView()
            }
        }
    }
}