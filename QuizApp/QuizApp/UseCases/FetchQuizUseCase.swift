import Foundation
import QuizRepo

/// Abstraction for fetching quiz data.
protocol FetchQuizUseCase {
    func execute() async throws -> [Quiz]
}

/// Implementation that fetches quiz data from a repository.
class FetchQuizUseCaseImpl: FetchQuizUseCase {
    private let repository: QuizAppRepository

    init(repository: QuizAppRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Quiz] {
        return try await repository.fetchQuizList()
    }
}
