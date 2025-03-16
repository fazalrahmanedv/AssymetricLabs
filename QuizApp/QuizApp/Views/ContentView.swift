import SwiftUI
import QuizRepo
import QuizUI
struct StreakView: View {
    var streak: Int = 3
    var body: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.red)
            Text("Streak: \(streak) day\(streak == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.1))
        )
        .padding(.horizontal)
    }
}
struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
}

struct AchievementsBanner: View {
    let achievements: [Achievement] = [
        Achievement(name: "Speedster", iconName: "bolt.fill"),
        Achievement(name: "Perfectionist", iconName: "checkmark.seal.fill"),
        Achievement(name: "Marathoner", iconName: "figure.walk"),
        Achievement(name: "Streak Master", iconName: "flame.fill")
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Achievements")
                .font(.headline)
                .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(achievements) { achievement in
                        VStack {
                            Image(systemName: achievement.iconName)
                                .font(.largeTitle)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.2))
                                )
                            Text(achievement.name)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 80)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}


struct ContentView: View {
    @StateObject private var viewModel = CountriesViewModel(
        fetchCountriesUseCase: FetchCountriesUseCaseImpl(repository: QuizAppRepositoryImpl())
    )
    @State private var searchText = ""
    @State private var selectedCountry: Countries?
    @State private var showPicker = false
    @State private var navigateToQuiz = false
    @State private var animateQuizButton = false
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    // Static background gradient based on the current color scheme.
    var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 14/255, green: 28/255, blue: 38/255),
                    Color(red: 42/255, green: 69/255, blue: 75/255),
                    Color(red: 41/255, green: 72/255, blue: 97/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 232/255, green: 217/255, blue: 202/255),
                    Color(red: 219/255, green: 206/255, blue: 192/255),
                    Color(red: 211/255, green: 198/255, blue: 185/255)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        StreakView()
                        AchievementsBanner()
                        
                        // Header section for country selection.
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Choose your country:")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.headline)
                            CountrySelectionButton(selectedCountry: $selectedCountry, showPicker: $showPicker)
                        }
                        .padding()
                        Spacer()
                        VStack(spacing: 20) {
                            Button(action: {
                                navigateToQuiz = true
                            }) {
                                HStack {
                                    Text("🧠")
                                        .font(.system(size: 24))
                                    Text("Start Quiz")
                                        .font(.system(size: 24, weight: .bold))
                                        .gradientForeground(colors: [Color.blue, Color.purple])
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding()
                            Button(action: {
                                // Action for solving bookmarks
                            }) {
                                Label {
                                    Text("Solve Bookmarks")
                                        .font(.system(size: 24, weight: .bold))
                                } icon: {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 24))
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .onAppear {
                        viewModel.loadData()
                    }
                    .sheet(isPresented: .constant(!hasOnboarded)) {
                        OnboardingView(
                            title: "Welcome to Infinity Quiz",
                            rows: [
                                OnboardingRow(
                                    image: Image(systemName: "questionmark.circle"),
                                    title: "Challenge Your Knowledge",
                                    description: "Test your brain with a range of trivia questions."
                                ),
                                OnboardingRow(
                                    image: Image(systemName: "lightbulb.fill"),
                                    title: "Discover New Facts",
                                    description: "Learn interesting trivia with every quiz."
                                ),
                                OnboardingRow(
                                    image: Image(systemName: "gamecontroller.fill"),
                                    title: "Fun & Engaging",
                                    description: "Enjoy quick, entertaining quizzes."
                                )
                            ],
                            actionTitle: "Get Started",
                            action: { hasOnboarded = true }
                        )
                    }
                    // Country Picker sheet.
                    .sheet(isPresented: $showPicker) {
                        CountryPickerView(
                            countries: viewModel.countryList,
                            searchText: $searchText,
                            selectedCountry: $selectedCountry,
                            showPicker: $showPicker
                        )
                    }
                    // Hidden navigation link to the QuizLandingPage.
                    NavigationLink(destination: QuizLandingPage(), isActive: $navigateToQuiz) {
                        EmptyView()
                    }
                    .hidden()
                }
                .navigationTitle("Infinity Quiz") // Apply navigationTitle here
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let country = selectedCountry {
                        Button(action: {
                            showPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Text(country.flag ?? "")
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
    }
}
extension View {
    func gradientText(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(self)
    }
}
extension View {
    func gradientForeground(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(self)
    }
}
