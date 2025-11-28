import SwiftUI

struct CocktailRowView: View {
    let cocktail: Cocktail
    @ObservedObject var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Зображення
            AsyncImage(url: URL(string: cocktail.thumbnail ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 60)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo")
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            
            // Інформація
            VStack(alignment: .leading, spacing: 4) {
                Text(cocktail.name)
                    .font(.headline)
                
                if let category = cocktail.category {
                    Text(category)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let alcoholic = cocktail.alcoholic {
                    Text(alcoholic)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Кнопка улюблених
            Button(action: {
                favoritesManager.toggleFavorite(cocktail.id)
            }) {
                Image(systemName: favoritesManager.isFavorite(cocktail.id) ? "heart.fill" : "heart")
                    .foregroundColor(favoritesManager.isFavorite(cocktail.id) ? .red : .gray)
                    .font(.title3)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
