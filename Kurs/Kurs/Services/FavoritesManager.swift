import Foundation
import Combine

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favorites: Set<String> = []
    private let key = "favoriteCocktails"
    
    private init() {
        loadFavorites()
    }
    
    func toggleFavorite(_ cocktailId: String) {
        if favorites.contains(cocktailId) {
            favorites.remove(cocktailId)
        } else {
            favorites.insert(cocktailId)
        }
        saveFavorites()
    }
    
    func isFavorite(_ cocktailId: String) -> Bool {
        favorites.contains(cocktailId)
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(Array(favorites)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            favorites = Set(decoded)
        }
    }
}
