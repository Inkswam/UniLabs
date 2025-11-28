import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = CocktailSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Поле пошуку
                HStack {
                    TextField("Пошук коктейлів...", text: $viewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await viewModel.search()
                            }
                        }
                    
                    Button("Шукати") {
                        Task {
                            await viewModel.search()
                        }
                    }
                    .padding(.trailing)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.searchText.isEmpty)
                }
                .padding(.top)
                
                // Контент
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Завантаження...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    Spacer()
                } else if viewModel.cocktails.isEmpty && !viewModel.searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Коктейлі не знайдено")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if !viewModel.cocktails.isEmpty {
                    List(viewModel.cocktails) { cocktail in
                        NavigationLink(destination: CocktailDetailView(cocktail: cocktail)) {
                            CocktailRowView(cocktail: cocktail)
                        }
                    }
                    .listStyle(.plain)
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Введіть назву коктейлю для пошуку")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Пошук Коктейлів")
        }
    }
}
