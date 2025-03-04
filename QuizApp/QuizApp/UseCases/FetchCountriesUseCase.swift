import Foundation
import QuizRepo
protocol FetchCountriesUseCase {
    func execute() async throws -> [QuizRepo.Countries]
}
class FetchCountriesUseCaseImpl: FetchCountriesUseCase {
    private let repository: QuizAppRepository
    init(repository: QuizAppRepository) {
        self.repository = repository
    }
    func execute() async throws -> [QuizRepo.Countries] {
        let countries = try await repository.fetchAppsList()
        return countries
    }
}
