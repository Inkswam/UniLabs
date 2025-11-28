import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Пошук", systemImage: "magnifyingglass")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Збережені", systemImage: "heart.fill")
                }
        }
    }
}
