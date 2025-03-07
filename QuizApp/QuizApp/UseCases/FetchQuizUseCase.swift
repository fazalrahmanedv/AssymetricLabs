//
//  FetchQuizUseCase.swift
//

import Foundation
import QuizRepo

protocol FetchQuizUseCase {
    func execute() async throws -> [Quiz]
}

class FetchQuizUseCaseImpl: FetchQuizUseCase {
    private let repository: QuizAppRepository
    init(repository: QuizAppRepository) {
        self.repository = repository
    }
    func execute() async throws -> [Quiz] {
        return try await repository.fetchQuizList()
    }
}
