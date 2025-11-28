import Foundation

struct Cocktail: Identifiable, Codable, Equatable {
    static func == (lhs: Cocktail, rhs: Cocktail) -> Bool {
        lhs.id == rhs.id
    }
    
    let id: String
    let name: String
    let category: String?
    let alcoholic: String?
    let glass: String?
    let instructions: String?
    let thumbnail: String?
    let ingredients: [String]
    let measures: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "idDrink"
        case name = "strDrink"
        case category = "strCategory"
        case alcoholic = "strAlcoholic"
        case glass = "strGlass"
        case instructions = "strInstructions"
        case thumbnail = "strDrinkThumb"
        case strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5
        case strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10
        case strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5
        case strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        alcoholic = try container.decodeIfPresent(String.self, forKey: .alcoholic)
        glass = try container.decodeIfPresent(String.self, forKey: .glass)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        
        var ingr: [String] = []
        var meas: [String] = []
        
        for i in 1...10 {
            if let key = CodingKeys(stringValue: "strIngredient\(i)"),
               let ingredient = try container.decodeIfPresent(String.self, forKey: key),
               !ingredient.isEmpty {
                ingr.append(ingredient)
            }
            if let key = CodingKeys(stringValue: "strMeasure\(i)"),
               let measure = try container.decodeIfPresent(String.self, forKey: key),
               !measure.isEmpty {
                meas.append(measure)
            }
        }
        
        ingredients = ingr
        measures = meas
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(alcoholic, forKey: .alcoholic)
        try container.encodeIfPresent(glass, forKey: .glass)
        try container.encodeIfPresent(instructions, forKey: .instructions)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
    }
}

struct CocktailResponse: Codable {
    let drinks: [Cocktail]?
}
