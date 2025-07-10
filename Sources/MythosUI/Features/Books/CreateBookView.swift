import SwiftUI
import MythosCore
import MythosNetworking

public struct CreateBookView: View {
    @StateObject private var bookService = BookService(apiClient: APIClient.shared)
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedGenre = Genre.fantasy
    @State private var tags = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    public var onBookCreated: (Book) -> Void
    
    public init(onBookCreated: @escaping (Book) -> Void) {
        self.onBookCreated = onBookCreated
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section(header: Text("Genre")) {
                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(Genre.allCases, id: \.self) { genre in
                            Text(genre.rawValue.capitalized)
                                .tag(genre)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Tags (Optional)")) {
                    TextField("Tags separated by commas", text: $tags)
                        .textInputAutocapitalization(.words)
                }
                
                Section {
                    Button(action: createBook) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("Create Book")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isFormValid)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Create Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var tagArray: [String] {
        tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func createBook() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let book = try await bookService.createBook(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                    genre: selectedGenre,
                    tags: tagArray,
                    language: "en"
                )
                
                await MainActor.run {
                    isLoading = false
                    onBookCreated(book)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    CreateBookView { book in
        print("Book created: \(book.title)")
    }
}