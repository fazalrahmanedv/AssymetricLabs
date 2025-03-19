import SwiftUI
import Combine
import QuizRepo

/// Manages quiz list state and navigation for the quiz session.
class QuizListViewModel: ObservableObject {
    @Published var quizList: [Quiz] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigate = false

    private let fetchQuizUseCase: FetchQuizUseCase
    private let minQuizCount = 5

    init(fetchQuizUseCase: FetchQuizUseCase) {
        self.fetchQuizUseCase = fetchQuizUseCase
    }

    /// Loads the quiz list asynchronously.
    @MainActor
    func loadQuizList() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        shouldNavigate = false

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let fetchedQuizzes = try await self.fetchQuizUseCase.execute()
                if fetchedQuizzes.count < self.minQuizCount {
                    self.errorMessage = "Not enough quizzes available."
                    self.shouldNavigate = false
                } else {
                    // Shuffle and trim the quizzes as needed.
                    self.quizList = Array(fetchedQuizzes.shuffled().prefix(self.minQuizCount))
                    self.shouldNavigate = true
                }
            } catch {
                self.handleError(error)
            }
            self.isLoading = false
        }
    }

    /// Handles errors by setting an error message and resetting state.
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        quizList = []
        shouldNavigate = false
    }
}
