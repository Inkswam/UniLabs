import Foundation
import Combine

@MainActor
class CocktailSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var cocktails: [Cocktail] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = CocktailService.shared
    
    func search() async {
        guard !searchText.isEmpty else {
            cocktails = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            cocktails = try await service.searchCocktails(query: searchText)
            if cocktails.isEmpty {
                errorMessage = "Коктейлі не знайдено"
            }
        } catch {
            errorMessage = "Помилка пошуку: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearSearch() {
        searchText = ""
        cocktails = []
        errorMessage = nil
    }
}
