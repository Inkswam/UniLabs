import SwiftUI
internal import Combine

// MARK: - Models (Data Layer)

struct Quote: Codable, Identifiable, Equatable {
    let id: Int
    let quote: String
    let author: String

    static func == (lhs: Quote, rhs: Quote) -> Bool {
        return lhs.id == rhs.id &&
               lhs.quote == rhs.quote &&
               lhs.author == rhs.author
    }
}

/// Відповідь API для списку цитат
struct QuotesResponse: Codable {
    let quotes: [Quote]
    let total: Int
    let skip: Int
    let limit: Int
}

// MARK: - Settings Model

/// Модель для збереження налаштувань
struct AppSettings: Codable, Equatable {
    var primaryColor: String
    var backgroundColor: String
    var fontSize: Double
    var fontName: String
    var showAuthorIcons: Bool
    var darkMode: Bool
    
    // Значення за замовчуванням
    static let `default` = AppSettings(
        primaryColor: "blue",
        backgroundColor: "white",
        fontSize: 16.0,
        fontName: "System",
        showAuthorIcons: true,
        darkMode: false
    )
}

// MARK: - Settings Manager

/// Менеджер для роботи з налаштуваннями в UserDefaults
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings = .default
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "appSettings"
    
    init() {
        loadSettings()
    }
    
    /// Завантаження налаштувань з UserDefaults
    func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let savedSettings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = savedSettings
        }
    }
    
    /// Збереження налаштувань в UserDefaults
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
            userDefaults.synchronize()
        }
    }
    
    /// Скидання налаштувань до значень за замовчуванням
    func resetSettings() {
        settings = .default
        saveSettings()
    }
}

// MARK: - File Manager Service

/// Сервіс для роботи з файловою системою
class FileManagerService {
    private let fileManager = FileManager.default
    
    /// Отримання URL директорії Documents
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// Збереження цитат у файл
    func saveQuotesToFile(_ quotes: [Quote], fileName: String) -> Bool {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let data = try JSONEncoder().encode(quotes)
            try data.write(to: fileURL)
            print("Цитати збережено у файл: \(fileURL.path)")
            return true
        } catch {
            print("Помилка збереження цитат: \(error)")
            return false
        }
    }
    
    /// Завантаження цитат з файлу
    func loadQuotesFromFile(fileName: String) -> [Quote] {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let quotes = try JSONDecoder().decode([Quote].self, from: data)
            print("Цитати завантажено з файлу: \(quotes.count) записів")
            return quotes
        } catch {
            print("Помилка завантаження цитат: \(error)")
            return []
        }
    }
    
    /// Перевірка існування файлу
    func fileExists(fileName: String) -> Bool {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Видалення файлу
    func deleteFile(fileName: String) -> Bool {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("Файл видалено: \(fileName)")
            return true
        } catch {
            print("Помилка видалення файлу: \(error)")
            return false
        }
    }
}

// MARK: - Data Layer (Network Service)

/// Сервіс для роботи з REST API цитат
class QuotesService {
    // Базовий URL API
    private let baseURL = "https://dummyjson.com/quotes"
    
    /// Отримання випадкової цитати
    func getRandomQuote() async throws -> Quote {
        let url = URL(string: "\(baseURL)/random")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Перевірка статус-коду відповіді
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // Декодування JSON
        let decoder = JSONDecoder()
        let quote = try decoder.decode(Quote.self, from: data)
        
        return quote
    }
    
    /// Отримання списку цитат з пагінацією
    func getQuotes(limit: Int = 10, skip: Int = 0) async throws -> QuotesResponse {
        let url = URL(string: "\(baseURL)?limit=\(limit)&skip=\(skip)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let quotesResponse = try decoder.decode(QuotesResponse.self, from: data)
        
        return quotesResponse
    }
    
    /// Отримання конкретної цитати за ID
    func getQuote(byId id: Int) async throws -> Quote {
        let url = URL(string: "\(baseURL)/\(id)")!
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let quote = try decoder.decode(Quote.self, from: data)
        
        return quote
    }
}

/// Типи помилок мережі
enum NetworkError: LocalizedError {
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Отримано некоректну відповідь від сервера"
        case .decodingError:
            return "Помилка обробки даних"
        }
    }
}

// MARK: - ViewModel

/// ViewModel для управління станом цитат
@MainActor
class QuotesViewModel: ObservableObject {
    // Published властивості для оновлення UI
    @Published var currentQuote: Quote?
    @Published var quotesList: [Quote] = []
    @Published var savedQuotes: [Quote] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 0
    @Published var searchText = ""
    @Published var selectedAuthor: String?
    
    private let service = QuotesService()
    private let fileService = FileManagerService()
    private let quotesPerPage = 10
    private let savedQuotesFileName = "saved_quotes.json"
    
    /// Список унікальних авторів
    var uniqueAuthors: [String] {
        let authors = quotesList.map { $0.author }
        return Array(Set(authors)).sorted()
    }
    
    /// Відфільтровані цитати за пошуком та автором
    var filteredQuotes: [Quote] {
        var filtered = quotesList
        
        // Фільтрація за пошуком
        if !searchText.isEmpty {
            filtered = filtered.filter { quote in
                quote.author.localizedCaseInsensitiveContains(searchText) ||
                quote.quote.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Фільтрація за обраним автором
        if let selectedAuthor = selectedAuthor {
            filtered = filtered.filter { $0.author == selectedAuthor }
        }
        
        return filtered
    }
    
    /// Завантаження випадкової цитати
    func loadRandomQuote() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                currentQuote = try await service.getRandomQuote()
            } catch {
                errorMessage = "Помилка завантаження цитати: \(error.localizedDescription)"
                print("Error loading random quote: \(error)")
            }
            
            isLoading = false
        }
    }
    
    /// Завантаження списку цитат
    func loadQuotes() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let response = try await service.getQuotes(
                    limit: quotesPerPage,
                    skip: currentPage * quotesPerPage
                )
                quotesList.append(contentsOf: response.quotes)
            } catch {
                errorMessage = "Помилка завантаження списку: \(error.localizedDescription)"
                print("Error loading quotes: \(error)")
            }
            
            isLoading = false
        }
    }
    
    /// Завантаження наступної сторінки
    func loadNextPage() {
        currentPage += 1
        loadQuotes()
    }
    
    /// Скидання списку цитат
    func resetQuotes() {
        currentPage = 0
        quotesList.removeAll()
        loadQuotes()
    }
    
    /// Скидання фільтрів
    func clearFilters() {
        searchText = ""
        selectedAuthor = nil
    }
    
    // MARK: - File Manager Methods
    
    /// Збереження поточної цитати
    func saveCurrentQuote() {
        guard let quote = currentQuote else { return }
        
        // Перевірка на дублікат
        if !savedQuotes.contains(where: { $0.id == quote.id }) {
            savedQuotes.append(quote)
            saveQuotesToFile()
        }
    }
    
    /// Збереження всіх цитат у файл
    func saveQuotesToFile() {
        let success = fileService.saveQuotesToFile(savedQuotes, fileName: savedQuotesFileName)
        if success {
            print("Улюблені цитати збережено успішно")
        }
    }
    
    /// Завантаження цитат з файлу
    func loadQuotesFromFile() {
        savedQuotes = fileService.loadQuotesFromFile(fileName: savedQuotesFileName)
    }
    
    /// Видалення цитати зі збережених
    func removeSavedQuote(_ quote: Quote) {
        savedQuotes.removeAll { $0.id == quote.id }
        saveQuotesToFile()
    }
    
    /// Перевірка чи цитата вже збережена
    func isQuoteSaved(_ quote: Quote) -> Bool {
        savedQuotes.contains { $0.id == quote.id }
    }
    
    /// Очищення всіх збережених цитат
    func clearSavedQuotes() {
        savedQuotes.removeAll()
        if fileService.fileExists(fileName: savedQuotesFileName) {
            _ = fileService.deleteFile(fileName: savedQuotesFileName)
        }
    }
}

// MARK: - Theme Manager

/// Менеджер для керування темами та кольорами
class ThemeManager: ObservableObject {
    @Published var settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    /// Отримання кольору за назвою
    func colorFromString(_ colorName: String) -> Color {
        switch colorName {
        case "blue":
            return .blue
        case "red":
            return .red
        case "green":
            return .green
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "black":
            return .black
        case "white":
            return .white
        case "gray":
            return .gray
        default:
            return .blue
        }
    }
    
    /// Отримання шрифту за назвою
    func fontFromString(_ fontName: String) -> Font {
        switch fontName {
        case "System":
            return .system(.body, design: .default)
        case "Rounded":
            return .system(.body, design: .rounded)
        case "Serif":
            return .system(.body, design: .serif)
        case "Monospaced":
            return .system(.body, design: .monospaced)
        default:
            return .body
        }
    }
    
    /// Отримання розміру шрифту
    func fontSize(_ size: Double) -> Double {
        return max(12.0, min(24.0, size))
    }
}

// MARK: - Views

/// Головний екран додатку
struct ContentView: View {
    @StateObject private var viewModel = QuotesViewModel()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var themeManager: ThemeManager
    
    init() {
        let settingsManager = SettingsManager()
        let themeManager = ThemeManager(settings: settingsManager.settings)
        _themeManager = StateObject(wrappedValue: themeManager)
    }
    
    var body: some View {
        TabView {
            // Вкладка з випадковою цитатою
            RandomQuoteView(viewModel: viewModel, themeManager: themeManager)
                .tabItem {
                    Label("Випадкова", systemImage: "shuffle")
                }
            
            // Вкладка зі списком цитат
            QuotesListView(viewModel: viewModel, themeManager: themeManager)
                .tabItem {
                    Label("Список", systemImage: "list.bullet")
                }
            
            // Вкладка з улюбленими цитатами
            SavedQuotesView(viewModel: viewModel, themeManager: themeManager)
                .tabItem {
                    Label("Улюблені", systemImage: "heart")
                }
            
            // Вкладка з налаштуваннями
            SettingsView(settingsManager: settingsManager, themeManager: themeManager, viewModel: viewModel)
                .tabItem {
                    Label("Налаштування", systemImage: "gear")
                }
        }
        .accentColor(themeManager.colorFromString(themeManager.settings.primaryColor))
        .preferredColorScheme(themeManager.settings.darkMode ? .dark : .light)
        .onAppear {
            // Завантаження збережених цитат при запуску
            viewModel.loadQuotesFromFile()
            // Оновлення теми при запуску
            themeManager.settings = settingsManager.settings
        }
        .onChange(of: settingsManager.settings) { newSettings in
            // Оновлення теми при зміні налаштувань
            themeManager.settings = newSettings
        }
    }
}

/// View для відображення випадкової цитати
struct RandomQuoteView: View {
    @ObservedObject var viewModel: QuotesViewModel
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градієнтний фон з використанням налаштувань
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.colorFromString(themeManager.settings.primaryColor).opacity(0.6),
                        themeManager.colorFromString(themeManager.settings.backgroundColor == "white" ? "purple" : themeManager.settings.backgroundColor).opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if viewModel.isLoading {
                        ProgressView("Завантаження...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                    } else if let quote = viewModel.currentQuote {
                        QuoteCard(quote: quote, themeManager: themeManager)
                        
                        // Кнопки дій
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.saveCurrentQuote()
                            }) {
                                VStack {
                                    Image(systemName: viewModel.isQuoteSaved(quote) ? "heart.fill" : "heart")
                                        .font(.title2)
                                    Text("Зберегти")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                shareQuote(quote)
                            }) {
                                VStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.title2)
                                    Text("Поділитись")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                            }
                        }
                    } else {
                        Text("Натисніть кнопку для отримання цитати")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    
                    // Кнопка отримання нової цитати
                    Button(action: {
                        viewModel.loadRandomQuote()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Нова цитата")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(themeManager.colorFromString(themeManager.settings.primaryColor))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    
                    // Відображення помилок
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Надихаюча цитата")
            .onAppear {
                // Автоматичне завантаження при першому відкритті
                if viewModel.currentQuote == nil {
                    viewModel.loadRandomQuote()
                }
            }
        }
    }
    
    private func shareQuote(_ quote: Quote) {
        let shareText = "\(quote.quote)\n— \(quote.author)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
}

/// Картка для відображення цитати
struct QuoteCard: View {
    let quote: Quote
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Іконка лапок
            Image(systemName: "quote.opening")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
            
            // Текст цитати
            Text(quote.quote)
                .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize), weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            // Автор
            HStack {
                Spacer()
                if themeManager.settings.showAuthorIcons {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
                Text("— \(quote.author)")
                    .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize - 2), weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .italic()
            }
            
            Image(systemName: "quote.closing")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
                .shadow(radius: 10)
        )
        .padding()
    }
}

/// View для відображення списку цитат
struct QuotesListView: View {
    @ObservedObject var viewModel: QuotesViewModel
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.quotesList.isEmpty && !viewModel.isLoading {
                    VStack {
                        Text("Список цитат порожній")
                            .foregroundColor(.gray)
                        Button("Завантажити") {
                            viewModel.loadQuotes()
                        }
                        .padding()
                        .background(themeManager.colorFromString(themeManager.settings.primaryColor))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    VStack {
                        
                        SearchAndFilterView(viewModel: viewModel, themeManager: themeManager)
                        
                        List {
                            ForEach(viewModel.filteredQuotes) { quote in
                                QuoteListRow(quote: quote, themeManager: themeManager)
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            if !viewModel.isQuoteSaved(quote) {
                                                viewModel.savedQuotes.append(quote)
                                                viewModel.saveQuotesToFile()
                                            }
                                        } label: {
                                            Label("Зберегти", systemImage: "heart")
                                        }
                                        .tint(.red)
                                    }
                            }
                            
                           
                            if !viewModel.quotesList.isEmpty && viewModel.selectedAuthor == nil {
                                Button(action: {
                                    viewModel.loadNextPage()
                                }) {
                                    HStack {
                                        Spacer()
                                        if viewModel.isLoading {
                                            ProgressView()
                                        } else {
                                            Text("Завантажити ще")
                                                .foregroundColor(themeManager.colorFromString(themeManager.settings.primaryColor))
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                
             
                if let error = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                            .padding()
                    }
                }
            }
            .navigationTitle("Всі цитати")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.resetQuotes()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if viewModel.quotesList.isEmpty {
                    viewModel.loadQuotes()
                }
            }
        }
    }
}


struct SavedQuotesView: View {
    @ObservedObject var viewModel: QuotesViewModel
    @ObservedObject var themeManager: ThemeManager
    
    @State private var selectedQuotes = Set<Int>()
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.savedQuotes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Немає збережених цитат")
                            .foregroundColor(.gray)
                        Text("Зберігайте цитати, натискаючи на ♥")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(viewModel.savedQuotes) { quote in
                            QuoteListRowWithSelection(
                                quote: quote,
                                themeManager: themeManager,
                                isSelected: selectedQuotes.contains(quote.id),
                                isEditing: isEditing
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isEditing {
                                    toggleSelection(for: quote)
                                }
                            }
                            //swipe delete
                            .swipeActions(edge: .trailing) {
                              
                                Button(role: .destructive) {
                                    viewModel.removeSavedQuote(quote)
                                } label: {
                                    Label("Видалити", systemImage: "trash")
                                }
                                
                               
                                if !isEditing {
                                    Button {
                                        toggleSelection(for: quote)
                                        isEditing = true
                                    } label: {
                                        Label("Вибрати", systemImage: "checkmark.circle")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Улюблені цитати")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.savedQuotes.isEmpty {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if isEditing {
                           
                            if !selectedQuotes.isEmpty {
                                Button("Видалити (\(selectedQuotes.count))") {
                                    deleteSelectedQuotes()
                                }
                                .foregroundColor(.red)
                            }
                            
                            Button("Готово") {
                                isEditing = false
                                selectedQuotes.removeAll()
                            }
                        } else {
                           
                            Menu {
                                Button("Вибрати цитати") {
                                    isEditing = true
                                }
                                
                                Button("Очистити всі", role: .destructive) {
                                    viewModel.clearSavedQuotes()
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
            }
          
            .onChange(of: viewModel.savedQuotes) { newQuotes in
                if newQuotes.isEmpty {
                    isEditing = false
                    selectedQuotes.removeAll()
                }
            }
        }
    }
    
    private func toggleSelection(for quote: Quote) {
        if selectedQuotes.contains(quote.id) {
            selectedQuotes.remove(quote.id)
        } else {
            selectedQuotes.insert(quote.id)
        }
        
        if selectedQuotes.isEmpty {
            isEditing = false
        }
    }
    //deleteing
    private func deleteSelectedQuotes() {
     
        for quoteId in selectedQuotes {
            if let quote = viewModel.savedQuotes.first(where: { $0.id == quoteId }) {
                viewModel.removeSavedQuote(quote)
            }
        }
        
    
        selectedQuotes.removeAll()
        isEditing = false
    }
}

/// Рядок з цитатою з можливістю вибору
struct QuoteListRowWithSelection: View {
    let quote: Quote
    @ObservedObject var themeManager: ThemeManager
    let isSelected: Bool
    let isEditing: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
          
            if isEditing {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? themeManager.colorFromString(themeManager.settings.primaryColor) : .gray)
                    .font(.title2)
                    .transition(.scale)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(quote.quote)
                    .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize)))
                    .foregroundColor(.primary)
                
                HStack {
                    if themeManager.settings.showAuthorIcons {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(themeManager.colorFromString(themeManager.settings.primaryColor))
                            .font(.caption)
                    }
                    Text("— \(quote.author)")
                        .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize - 2)))
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.2), value: isEditing)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// Панель пошуку та фільтрів
struct SearchAndFilterView: View {
    @ObservedObject var viewModel: QuotesViewModel
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Пошук за автором або текстом...", text: $viewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            
            //auth filter
            if !viewModel.uniqueAuthors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Фільтр за автором:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if viewModel.selectedAuthor != nil || !viewModel.searchText.isEmpty {
                            Button("Скинути") {
                                viewModel.clearFilters()
                            }
                            .font(.caption)
                            .foregroundColor(themeManager.colorFromString(themeManager.settings.primaryColor))
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.uniqueAuthors, id: \.self) { author in
                                AuthorFilterChip(
                                    author: author,
                                    isSelected: viewModel.selectedAuthor == author,
                                    onSelect: {
                                        if viewModel.selectedAuthor == author {
                                            viewModel.selectedAuthor = nil
                                        } else {
                                            viewModel.selectedAuthor = author
                                        }
                                    },
                                    themeManager: themeManager
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Інформація про результати
            if !viewModel.filteredQuotes.isEmpty || !viewModel.quotesList.isEmpty {
                HStack {
                    Text("Показано: \(viewModel.filteredQuotes.count) з \(viewModel.quotesList.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if viewModel.selectedAuthor != nil {
                        Text("Автор: \(viewModel.selectedAuthor!)")
                            .font(.caption)
                            .foregroundColor(themeManager.colorFromString(themeManager.settings.primaryColor))
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

/// Чіп для фільтрації за автором
struct AuthorFilterChip: View {
    let author: String
    let isSelected: Bool
    let onSelect: () -> Void
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onSelect) {
            Text(author)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? themeManager.colorFromString(themeManager.settings.primaryColor) : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

/// Рядок для відображення цитати у списку
struct QuoteListRow: View {
    let quote: Quote
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.quote)
                .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize)))
                .foregroundColor(.primary)
            
            HStack {
                if themeManager.settings.showAuthorIcons {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(themeManager.colorFromString(themeManager.settings.primaryColor))
                        .font(.caption)
                }
                Text("— \(quote.author)")
                    .font(.system(size: themeManager.fontSize(themeManager.settings.fontSize - 2)))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

/// View для налаштувань
struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var viewModel: QuotesViewModel
    
    @State private var showResetConfirmation = false
    @State private var showSaveConfirmation = false
    @State private var showResetSettingsConfirmation = false
    
    let colors = ["blue", "red", "green", "orange", "purple", "pink", "black"]
    let fonts = ["System", "Rounded", "Serif", "Monospaced"]
    
    var body: some View {
        NavigationView {
            Form {
                // Секція кольорів
                Section(header: Text("Кольори")) {
                    Picker("Основний колір", selection: $settingsManager.settings.primaryColor) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(themeManager.colorFromString(color))
                                    .frame(width: 20, height: 20)
                                Text(color.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    
                    Picker("Колір фону", selection: $settingsManager.settings.backgroundColor) {
                        ForEach(colors, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(themeManager.colorFromString(color))
                                    .frame(width: 20, height: 20)
                                Text(color.capitalized)
                            }
                            .tag(color)
                        }
                    }
                }
                
                // Секція шрифтів
                Section(header: Text("Шрифти")) {
                    Picker("Шрифт", selection: $settingsManager.settings.fontName) {
                        ForEach(fonts, id: \.self) { font in
                            Text(font).tag(font)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Розмір шрифту: \(Int(settingsManager.settings.fontSize))")
                        Slider(value: $settingsManager.settings.fontSize, in: 12...24, step: 1)
                    }
                }
                
                // Секція інтерфейсу
                Section(header: Text("Інтерфейс")) {
                    Toggle("Темна тема", isOn: $settingsManager.settings.darkMode)
                    Toggle("Показувати іконки авторів", isOn: $settingsManager.settings.showAuthorIcons)
                }
                
                // Секція даних
                Section(header: Text("Дані")) {
                    Button("Зберегти улюблені цитати") {
                        viewModel.saveQuotesToFile()
                        showSaveConfirmation = true
                    }
                    .foregroundColor(themeManager.colorFromString(settingsManager.settings.primaryColor))
                    
                    Button("Очистити улюблені цитати") {
                        showResetConfirmation = true
                    }
                    .foregroundColor(.red)
                }
                
                // Секція скидання
                Section {
                    Button("Скинути налаштування") {
                        showResetSettingsConfirmation = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Налаштування")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Зберегти") {
                        settingsManager.saveSettings()
                    }
                }
            }
            .alert("Цитати збережено", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            }
            .alert("Очистити улюблені цитати?", isPresented: $showResetConfirmation) {
                Button("Скасувати", role: .cancel) { }
                Button("Очистити", role: .destructive) {
                    viewModel.clearSavedQuotes()
                }
            } message: {
                Text("Ця дія незворотна. Всі збережені цитати будуть видалені.")
            }
            .alert("Скинути налаштування?", isPresented: $showResetSettingsConfirmation) {
                Button("Скасувати", role: .cancel) { }
                Button("Скинути", role: .destructive) {
                    settingsManager.resetSettings()
                }
            } message: {
                Text("Всі налаштування будуть скинуті до значень за замовчуванням.")
            }
            .onChange(of: settingsManager.settings) { _ in
                // Автозбереження при зміні налаштувань
                settingsManager.saveSettings()
            }
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
