import SwiftUI
import QuizRepo
public struct CountrySelectionButton: View {
    @Binding public var selectedCountry: QuizRepo.Countries?
    @Binding public var showPicker: Bool
    public init(selectedCountry: Binding<QuizRepo.Countries?>, showPicker: Binding<Bool>) {
        self._selectedCountry = selectedCountry
        self._showPicker = showPicker
    }
    public var body: some View {
        Button {
            showPicker.toggle()
        } label: {
            HStack {
                Text("\(selectedCountry?.flag ?? "") \(selectedCountry?.name ?? "Select a Country")")
                Spacer()
                Image(systemName: "chevron.down")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
        }
    }
}
