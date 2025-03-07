import SwiftUI
import QuizRepo
import QuizUI

struct ContentView: View {
    @StateObject private var viewModel = CountriesViewModel(
        fetchCountriesUseCase: FetchCountriesUseCaseImpl(repository: QuizAppRepositoryImpl())
    )
    @State private var searchText = ""
    @State private var selectedCountry: Countries?
    @State private var showPicker = false
    @State private var navigateToQuiz = false
    @State private var navigateToBookmarkedQuiz = false
    @State private var animateQuizButton = false
    @State private var animateHeader = false
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) var colorScheme
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
                backgroundGradient.ignoresSafeArea()
                VStack(spacing: 20) {
                    // Animated Header to set a fun tone
                    Text("Infinity Quiz")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose your country:")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        CountrySelectionButton(selectedCountry: $selectedCountry, showPicker: $showPicker)
                    }
                    .padding()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            navigateToQuiz = true
                        }) {
                            Text("Start Quiz")
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        // Pulsating animation for the quiz button
                        .scaleEffect(animateQuizButton ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateQuizButton)
                        .onAppear {
                            animateQuizButton = true
                        }
                        
                        Button(action: {
                            navigateToBookmarkedQuiz = true
                        }) {
                            Text("Bookmarked")
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                }
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.horizontal, 20)
                .onAppear {
                    viewModel.loadData()
                }
                NavigationLink(
                    destination: QuizSummaryView(viewModel: QuizViewModel(quizList: [])),
                    isActive: $navigateToBookmarkedQuiz
                ) {
                    EmptyView()
                }
                .hidden()
                #if !os(tvOS)
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
                .sheet(isPresented: $showPicker) {
                    CountryPickerView(
                        countries: viewModel.countryList,
                        searchText: $searchText,
                        selectedCountry: $selectedCountry,
                        showPicker: $showPicker
                    )
                }
                #endif
                
                NavigationLink(destination: QuizLandingPage(), isActive: $navigateToQuiz) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationTitle("Home")
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
