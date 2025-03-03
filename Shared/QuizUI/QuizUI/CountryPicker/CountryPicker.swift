import SwiftUI
import QuizRepo
import CoreData
public struct CountryPickerView: View {
    public let countries: [QuizRepo.Countries]
    @Binding public var searchText: String
    @Binding public var selectedCountry: QuizRepo.Countries?
    @Binding public var showPicker: Bool
    @Environment(\.dismiss) private var dismiss
    public init(
        countries: [QuizRepo.Countries],
        searchText: Binding<String>,
        selectedCountry: Binding<QuizRepo.Countries?>,
        showPicker: Binding<Bool>
    ) {
        self.countries = countries
        self._searchText = searchText
        self._selectedCountry = selectedCountry
        self._showPicker = showPicker
    }
    private var filteredCountries: [QuizRepo.Countries] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { country in
                country.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    public var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack {
                    // Search Bar
                    TextField("Search Country...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    List(filteredCountries, id: \.self) { country in
                        Button {
                            selectedCountry = country
                            dismiss() // Close picker after selection
                        } label: {
                            countryRowView(country)
                        }
                    }
                    .overlay {
                        if filteredCountries.isEmpty {
                            if #available(iOS 17.0, *) {
                                ContentUnavailableView("No countries found", systemImage: "magnifyingglass")
                            } else {
                                VStack {
                                    Image(systemName: "magnifyingglass")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.gray)
                                    Text("No countries found")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                }
                .navigationTitle("Select a Country")
                .navigationBarTitleDisplayMode(.inline) // Small inline title
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func countryRowView(_ country: Countries) -> some View {
        HStack {
            Text("\(country.flag ?? "") \(country.name ?? "")")
            Spacer()
        }
    }

}
