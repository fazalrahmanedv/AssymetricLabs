//
//  QuizListViewModel.swift
//

import Combine
import QuizRepo

class QuizListViewModel: ObservableObject {
    @Published var quizList: [Quiz] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var shouldNavigate: Bool = false
    
    private let fetchQuizUseCase: FetchQuizUseCase
    private let minQuizCount = 5
    private var cancellables = Set<AnyCancellable>()

    init(fetchQuizUseCase: FetchQuizUseCase) {
        self.fetchQuizUseCase = fetchQuizUseCase
    }
    
    func loadQuizList() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        shouldNavigate = false
        
        Task {
            do {
                let quizzes = try await fetchQuizUseCase.execute()
                await MainActor.run {
                    self.validateAndPrepareQuizzes(quizzes)
                }
            } catch {
                await handleError(error)
            }
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    @MainActor
    private func validateAndPrepareQuizzes(_ quizzes: [Quiz]) {
        let validQuizzes = quizzes.filter { quiz in
            [quiz.question, quiz.option1, quiz.option2, quiz.option3, quiz.option4]
                .allSatisfy { $0?.isEmpty == false }
        }
        
        guard validQuizzes.count >= minQuizCount else {
            errorMessage = validQuizzes.isEmpty ?
                "No quizzes available" :
                "Minimum \(minQuizCount) quizzes required (\(validQuizzes.count) available)"
            quizList = []
            return
        }
        
        quizList = Array(validQuizzes.shuffled().prefix(minQuizCount))
        shouldNavigate = true
    }
    
    @MainActor
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        quizList = []
        shouldNavigate = false
    }
}
