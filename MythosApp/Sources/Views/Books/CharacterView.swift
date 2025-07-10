import SwiftUI

// MARK: - Character View
struct CharacterView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("Characters")
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                Spacer()
            }
            .background(
                LinearGradient(
                    colors: [Color.brandPink, Color.brandPurple, Color.brandBlue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Characters")
        }
    }
}

// MARK: - Character Card
struct CharacterCard: View {
    let character: Character
    
    var body: some View {
        VStack(spacing: 12) {
            // Character Avatar
            AsyncImage(url: character.avatarUrl != nil ? URL(string: character.avatarUrl!) : nil) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.brandPink.opacity(0.3), Color.brandPurple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: "person.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.6))
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(character.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("\(character.likeCount)")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .cardStyle()
    }
}