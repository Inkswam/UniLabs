import SwiftUI
import Photos

struct CocktailDetailView: View {
    let cocktail: Cocktail
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var cocktailImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Головне зображення
                AsyncImage(url: URL(string: cocktail.thumbnail ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                            .onAppear {
                                // Конвертуємо Image в UIImage для збереження
                                if let uiImage = ImageRenderer(content: image).uiImage {
                                    cocktailImage = uiImage
                                }
                            }
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Основна інформація
                VStack(alignment: .leading, spacing: 16) {
                    // Назва та кнопки
                    HStack(alignment: .top) {
                        Text(cocktail.name)
                            .font(.title)
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                        
                        // Кнопка збереження фото
                        Button(action: {
                            saveImageToPhotos()
                        }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 8)
                        
                        // Кнопка улюблених
                        Button(action: {
                            favoritesManager.toggleFavorite(cocktail.id)
                        }) {
                            Image(systemName: favoritesManager.isFavorite(cocktail.id) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(favoritesManager.isFavorite(cocktail.id) ? .red : .gray)
                        }
                    }
                    
                    // Додаткова інформація
                    VStack(alignment: .leading, spacing: 8) {
                        if let category = cocktail.category {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.blue)
                                Text(category)
                            }
                            .font(.subheadline)
                        }
                        
                        if let alcoholic = cocktail.alcoholic {
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.purple)
                                Text(alcoholic)
                            }
                            .font(.subheadline)
                        }
                        
                        if let glass = cocktail.glass {
                            HStack {
                                Image(systemName: "wineglass")
                                    .foregroundColor(.orange)
                                Text(glass)
                            }
                            .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Інгредієнти
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Інгредієнти")
                            .font(.title2)
                            .bold()
                        
                        ForEach(Array(cocktail.ingredients.enumerated()), id: \.offset) { index, ingredient in
                            HStack(alignment: .top) {
                                Text("•")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                Text(ingredient)
                                    .font(.body)
                                
                                Spacer()
                                
                                if index < cocktail.measures.count {
                                    Text(cocktail.measures[index])
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Інструкція приготування
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Інструкція приготування")
                            .font(.title2)
                            .bold()
                        
                        if let instructions = cocktail.instructions {
                            Text(instructions)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("Інструкція відсутня")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Збереження фото", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func saveImageToPhotos() {
        // Перевіряємо чи є зображення
        guard let image = cocktailImage else {
            saveAlertMessage = "Зображення ще не завантажено"
            showingSaveAlert = true
            return
        }
        
        // Перевіряємо дозвіл на доступ до фотогалереї
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .notDetermined:
            // Запитуємо дозвіл
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        performSave(image: image)
                    } else {
                        saveAlertMessage = "Доступ до фотогалереї заборонено. Увімкніть його в Налаштуваннях"
                        showingSaveAlert = true
                    }
                }
            }
        case .authorized, .limited:
            performSave(image: image)
        case .denied, .restricted:
            saveAlertMessage = "Доступ до фотогалереї заборонено. Увімкніть його в Налаштуваннях"
            showingSaveAlert = true
        @unknown default:
            saveAlertMessage = "Помилка доступу до фотогалереї"
            showingSaveAlert = true
        }
    }
    
    private func performSave(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveAlertMessage = "✅ Фото успішно збережено в галерею!"
                } else {
                    saveAlertMessage = "❌ Помилка збереження: \(error?.localizedDescription ?? "Невідома помилка")"
                }
                showingSaveAlert = true
            }
        }
    }
}
