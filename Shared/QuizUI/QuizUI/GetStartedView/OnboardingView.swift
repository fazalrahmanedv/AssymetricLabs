import SwiftUI
public struct OnboardingView: View {
    let title: LocalizedStringKey
    let rows: [OnboardingRow]
    let actionTitle: LocalizedStringKey
    let action: () -> Void
    public init(
        title: LocalizedStringKey,
        rows: [OnboardingRow],
        actionTitle: LocalizedStringKey,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.rows = rows
        self.actionTitle = actionTitle
        self.action = action
    }
    public var body: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 0)
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(32)
            if #available(iOS 16.4, *) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(rows, id: \.id) { row in
                            row
                        }
                    }
                    .padding(32)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            if #available(iOS 15.0, *) {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .buttonStyle(.borderedProminent)
                .padding(32)
            }
        }
    }
}
