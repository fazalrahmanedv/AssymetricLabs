import QuizRepo
class QuizListViewModel: ObservableObject {
    @Published var quizList: [QuizRepo.Quiz] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private let fetchQuizUseCase: FetchQuizUseCase
    init(fetchQuizUseCase: FetchQuizUseCase) {
        self.fetchQuizUseCase = fetchQuizUseCase
    }
    func loadQuizList() {
        isLoading = true
        errorMessage = nil
        Task {
            await fetchQuizzes()
        }
    }
    @MainActor
    private func fetchQuizzes() async {
        do {
            self.quizList = getRandomQuizzes(from: try await fetchQuizUseCase.execute(), count: 5)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    private func getRandomQuizzes(from quizzes: [Quiz], count: Int) -> [Quiz] {
        return Array(quizzes.shuffled().prefix(count))
    }
}
