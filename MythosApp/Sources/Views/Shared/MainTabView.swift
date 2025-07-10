import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    var body: some View {
        TabView {
            BookshelfView()
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("Library")
                }
            
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            CategoriesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Categories")
                }
            
            CharacterView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Characters")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.brandPink)
        .background(Color.white.ignoresSafeArea())
    }
}