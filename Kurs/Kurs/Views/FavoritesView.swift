import SwiftUI

struct FavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var favoriteCocktails: [Cocktail] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Завантаження...")
                } else if favoriteCocktails.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Немає збережених коктейлів")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Додайте коктейлі до улюблених під час пошуку")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List(favoriteCocktails) { cocktail in
                        NavigationLink(destination: CocktailDetailView(cocktail: cocktail)) {
                            CocktailRowView(cocktail: cocktail)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Збережені")
            .onAppear {
                loadFavorites()
            }
            .onChange(of: favoritesManager.favorites) {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        Task { @MainActor in
            isLoading = true
            var cocktails: [Cocktail] = []
            
            for id in favoritesManager.favorites {
                if let cocktail = try? await CocktailService.shared.getCocktailById(id: id) {
                    cocktails.append(cocktail)
                }
            }
            
            self.favoriteCocktails = cocktails.sorted { $0.name < $1.name }
            self.isLoading = false
        }
    }
}
