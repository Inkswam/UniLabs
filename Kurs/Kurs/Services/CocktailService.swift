import Foundation

class CocktailService {
    static let shared = CocktailService()
    private let baseURL = "https://www.thecocktaildb.com/api/json/v1/1"
    
    private init() {}
    
    func searchCocktails(query: String) async throws -> [Cocktail] {
        let urlString = "\(baseURL)/search.php?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CocktailResponse.self, from: data)
        return response.drinks ?? []
    }
    
    func getCocktailById(id: String) async throws -> Cocktail? {
        let urlString = "\(baseURL)/lookup.php?i=\(id)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(CocktailResponse.self, from: data)
        return response.drinks?.first
    }
}
