import QuizRepo

/// Manages country data and loading state.
class CountriesViewModel: ObservableObject {
    @Published var countryList: [Countries] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchCountriesUseCase: FetchCountriesUseCase

    init(fetchCountriesUseCase: FetchCountriesUseCase) {
        self.fetchCountriesUseCase = fetchCountriesUseCase
    }

    /// Initiates loading of country data.
    func loadCountryList() {
        isLoading = true
        errorMessage = nil
        Task { [weak self] in
            await self?.fetchCountryList()
        }
    }

    @MainActor
    private func fetchCountryList() async {
        do {
            self.countryList = try await fetchCountriesUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
