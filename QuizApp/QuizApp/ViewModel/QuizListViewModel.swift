import SwiftUI
import Combine
import QuizRepo
// MARK: - QuizListViewModel
class QuizListViewModel: ObservableObject {
    @Published var quizList: [Quiz] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigate = false
    private let fetchQuizUseCase: FetchQuizUseCase
    private let minQuizCount = 5
    private var cancellables = Set<AnyCancellable>()
    init(fetchQuizUseCase: FetchQuizUseCase) {
        self.fetchQuizUseCase = fetchQuizUseCase
    }
    @MainActor
    func loadQuizList() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        shouldNavigate = false
        Task {
            do {
                // Directly fetch the quizzes; they are already validated.
                let fetchedQuizzes = try await fetchQuizUseCase.execute()
                quizList = fetchedQuizzes
                // Optionally, ensure you have a minimum number of quizzes to proceed.
                if quizList.count < minQuizCount {
                    errorMessage = "Not enough quizzes available."
                    shouldNavigate = false
                } else {
                    // Optionally, you could shuffle or trim the quizzes if needed.
                    quizList = Array(quizList.shuffled().prefix(minQuizCount))
                    shouldNavigate = true
                }
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        quizList = []
        shouldNavigate = false
    }
}
