import SwiftUI
internal import Combine

// MARK: - Models (Data Layer)

/// Модель для представлення цитати з DummyJSON API
struct Quote: Codable, Identifiable {
    let id: Int
    let quote: String
    let author: String
}

/// Відповідь API для списку цитат
struct QuotesResponse: Codable {
    let quotes: [Quote]
    let total: Int
    let skip: Int
    let limit: Int
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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPage = 0
    @Published var searchText = ""
    @Published var selectedAuthor: String?
    
    private let service = QuotesService()
    private let quotesPerPage = 10
    
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
}

// MARK: - Views

/// Головний екран додатку
struct ContentView: View {
    @StateObject private var viewModel = QuotesViewModel()
    
    var body: some View {
        TabView {
            // Вкладка з випадковою цитатою
            RandomQuoteView(viewModel: viewModel)
                .tabItem {
                    Label("Випадкова", systemImage: "shuffle")
                }
            
            // Вкладка зі списком цитат
            QuotesListView(viewModel: viewModel)
                .tabItem {
                    Label("Список", systemImage: "list.bullet")
                }
        }
    }
}

/// View для відображення випадкової цитати
struct RandomQuoteView: View {
    @ObservedObject var viewModel: QuotesViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Градієнтний фон
                LinearGradient(
                    gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
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
                        QuoteCard(quote: quote)
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
                        .background(Color.blue)
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
}

/// Картка для відображення цитати
struct QuoteCard: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Іконка лапок
            Image(systemName: "quote.opening")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
            
            // Текст цитати
            Text(quote.quote)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            // Автор
            HStack {
                Spacer()
                Text("— \(quote.author)")
                    .font(.headline)
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    VStack {
                        // Панель пошуку та фільтрів
                        SearchAndFilterView(viewModel: viewModel)
                        
                        List {
                            ForEach(viewModel.filteredQuotes) { quote in
                                QuoteListRow(quote: quote)
                            }
                            
                            // Кнопка завантаження більше
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
                                                .foregroundColor(.blue)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Відображення помилок
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

/// Панель пошуку та фільтрів
struct SearchAndFilterView: View {
    @ObservedObject var viewModel: QuotesViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            // Поле пошуку
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
            
            // Фільтр за авторами
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
                            .foregroundColor(.blue)
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
                                    }
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
                            .foregroundColor(.blue)
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
    
    var body: some View {
        Button(action: onSelect) {
            Text(author)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

/// Рядок для відображення цитати у списку
struct QuoteListRow: View {
    let quote: Quote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.quote)
                .font(.body)
                .foregroundColor(.primary)
            
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
