import SwiftUI
import QuizRepo
import CoreData

public struct CountryPickerView: View {
    public let countries: [Countries]
    @Binding public var searchText: String
    @Binding public var selectedCountry: Countries?
    @Binding public var showPicker: Bool
    
    public init(
        countries: [Countries],
        searchText: Binding<String>,
        selectedCountry: Binding<Countries?>,
        showPicker: Binding<Bool>
    ) {
        self.countries = countries
        self._searchText = searchText
        self._selectedCountry = selectedCountry
        self._showPicker = showPicker
    }
    
    private var filteredCountries: [Countries] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { country in
                country.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    public var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                // Use NavigationStack for iOS 16+
                NavigationStack {
                    content
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Close") {
                                    showPicker = false
                                }
                            }
                        }
                }
            } else {
                // Use NavigationView for iOS 14+
                NavigationView {
                    content
                        .navigationBarTitle("Select a Country", displayMode: .inline)
                        .navigationBarItems(trailing: Button("Close") {
                            showPicker = false
                        })
                }
            }
        }
    }
    
    private var content: some View {
        VStack {
            // Search Bar
            TextField("Search Country...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Use ZStack to overlay empty state for iOS 14+ fallback
            ZStack {
                List(filteredCountries, id: \.self) { country in
                    Button {
                        selectedCountry = country
                        showPicker = false
                    } label: {
                        countryRowView(country)
                    }
                }
                
                if filteredCountries.isEmpty {
                    noResultsView
                        .transition(.opacity) // Optional fade-in for smooth UI
                }
            }
        }
    }
    
    @ViewBuilder
    private func countryRowView(_ country: Countries) -> some View {
        HStack {
            Text("\(country.flag ?? "") \(country.name ?? "")")
            Spacer()
        }
    }
    
    @ViewBuilder
    private var noResultsView: some View {
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
