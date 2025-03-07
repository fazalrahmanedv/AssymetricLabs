import QuizRepo
class CountriesViewModel: ObservableObject {
    @Published var countryList: [Countries] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private let fetchCountriesUseCase: FetchCountriesUseCase
    init(fetchCountriesUseCase: FetchCountriesUseCase) {
        self.fetchCountriesUseCase = fetchCountriesUseCase
    }
    func loadData() {
        isLoading = true
        errorMessage = nil
        Task {
            await fetchCountryList()
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
