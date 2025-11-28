import SwiftUI

struct ContentView: View {
    // Стани для TextField
    @State private var userName: String = "Іван Петренко"
    @State private var userEmail: String = "ivan.petrenko@example.com"
    @State private var userPhone: String = "+380 XX XXX XX XX"
    @State private var userBio: String = "Студент 3-го курсу..."
    
    var body: some View {
        // Головний контейнер з прокруткою
        ScrollView {
            // Вертикальний стек для всіх елементів
            VStack(spacing: 20) {
                
                // === HEADER SECTION з ZStack ===
                ZStack {
                    // Фоновий градієнт
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 250)
                    .cornerRadius(20)
                    .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Контент поверх фону
                    VStack(spacing: 15) {
                        // Фото профілю (своє фото)
                        Image("pf")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        // Ім'я (відображається зі стану)
                        Text(userName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Спеціальність
                        Text("Студент ІТ факультету")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal)
                
                // === EDIT PROFILE SECTION з TextField ===
                VStack(alignment: .leading, spacing: 15) {
                    Text("Редагувати профіль")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 5)
                    
                    // TextField для імені
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Ім'я:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Введіть ім'я", text: $userName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                   
                        
                        HStack(spacing: 300) {
                            Image(systemName: "car.fill")
                                     .foregroundColor(.brown)
                                     .font(.system(size: 24))
                                 
                                 Image(systemName: "book.fill")
                                     .foregroundColor(.brown)
                                     .font(.system(size: 24))
                             }
                    }
                    
                    // TextField для email
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Введіть email", text: $userEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // TextField для телефону
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Телефон:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Введіть телефон", text: $userPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                            .keyboardType(.phonePad)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(15)
                .padding(.horizontal)
                
                // === CONTACT INFO з HStack ===
                VStack(alignment: .leading, spacing: 15) {
                    Text("Контактна інформація")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Email (відображається зі стану)
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Text(userEmail)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Телефон (відображається зі стану)
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Text(userPhone)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Локація
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                            .frame(width: 30)
                        
                        Text("Львів, Україна")
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // === BIO SECTION з TextField (багаторядковий) ===
                VStack(alignment: .leading, spacing: 10) {
                    Text("Про мене")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Багаторядковий TextField
                    TextField("Розкажіть про себе...", text: $userBio, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                        .padding()
                        .frame(minHeight: 100, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // === SKILLS з декількома HStack ===
                VStack(alignment: .leading, spacing: 10) {
                    Text("Навички")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Перший ряд навичок
                    HStack(spacing: 10) {
                        SkillBadge(icon: "chevron.left.forwardslash.chevron.right", title: "C#", color: .purple)
                        SkillBadge(icon: "a.circle.fill", title: "Angular", color: .red)
                        SkillBadge(icon: "dot.square.fill", title: ".NET", color: .blue)
                    }
                    
                    // Другий ряд навичок
                    HStack(spacing: 10) {
                        SkillBadge(icon: "cylinder.fill", title: "SQL", color: .orange)
                        SkillBadge(icon: "server.rack", title: "Backend", color: .green)
                        SkillBadge(icon: "globe", title: "Web", color: .cyan)
                    }
                }
                .padding(.horizontal)
                
                // === HOBBIES ===
                VStack(alignment: .leading, spacing: 10) {
                    Text("Хобі та інтереси")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        HobbyRow(icon: "book.fill", text: "Читання детективів", color: .brown)
                        HobbyRow(icon: "music.note", text: "Музика", color: .pink)
                        HobbyRow(icon: "gamecontroller.fill", text: "Ігри", color: .indigo)
                        HobbyRow(icon: "figure.walk", text: "Спорт", color: .orange)
                    }
                }
                .padding(.horizontal)
                
                // === FOOTER з ZStack ===
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 80)
                    
                    VStack(spacing: 5) {
                        Text("© 2024 " + userName)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 15) {
                            Image(systemName: "github")
                            
                            // Посилання на Steam
                            Link(destination: URL(string: "https://steamcommunity.com/id/-Wagner-/")!) {
                                Image(systemName: "link")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                            
                            Image(systemName: "envelope")
                        }
                        .font(.title3)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
    }
}



// Компонент для відображення навичок
struct SkillBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Компонент для відображення хобі
struct HobbyRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

// Попередній перегляд
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
