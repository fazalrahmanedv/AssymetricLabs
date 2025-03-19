import Foundation
import QuizRepo

/// Abstraction for fetching country data.
protocol FetchCountriesUseCase {
    func execute() async throws -> [Countries]
}

/// Implementation that fetches country data from a repository.
class FetchCountriesUseCaseImpl: FetchCountriesUseCase {
    private let repository: QuizAppRepository

    init(repository: QuizAppRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Countries] {
        return try await repository.fetchCountryList()
    }
}
