import SwiftUI
struct QuizLandingPage: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = QuizListViewModel(
        fetchQuizUseCase: FetchQuizUseCaseImpl(repository: QuizAppRepositoryImpl())
    )
    @State private var isQuizActive = false
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
        ZStack {
            backgroundGradient.ignoresSafeArea()
            VStack {
                // Top information views with a pulsing effect.
                HStack(alignment: .top, spacing: 20) {
                    quizInfoView(title: "5 MCQs", subtitle: "Questions")
                    quizInfoView(title: "One", subtitle: "Attempt")
                    quizInfoView(title: "5 minutes", subtitle: "Total time")
                }
                Spacer()
                VStack {
                    Text("You have 5 minutes to complete this Quiz")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .transition(.slide)
                    Text("All the best")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .transition(.slide)
                }
                Spacer()
                VStack {
                    // NavigationLink to trigger when quiz data is ready.
                    NavigationLink(
                        destination: QuizView(quizList: viewModel.quizList),
                        isActive: $isQuizActive
                    ) {
                        EmptyView()
                    }
                    
                    // Show loading indicator or the Continue button.
                    if viewModel.isLoading {
                        ProgressView("Loading quizzes...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .padding()
                    } else {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.loadQuizList()
                        }) {
                            HStack(spacing: 4) {
                                Text("Continue")
                                if #available(iOS 17.0, *) {
                                    Image(systemName: "arrow.right")
                                        .symbolEffect(.pulse, options: .repeating, isActive: true)
                                } else {
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    Text("Tap continue when you are ready to take the quiz")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
        .onChange(of: viewModel.shouldNavigate) { newValue in
            if newValue {
                isQuizActive = true
            }
        }
    }
    
    @ViewBuilder
    func quizInfoView(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.quaternarySystemFill))
        .cornerRadius(8)
    }
}

struct QuizLandingPage_Previews: PreviewProvider {
    static var previews: some View {
        QuizLandingPage()
            .previewLayout(.sizeThatFits)
    }
}
