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

            // Title Section
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(32)

            // Scrollable Rows
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
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(rows, id: \.id) { row in
                            row
                        }
                    }
                    .padding(32)
                }
            }
            // Action Button
            if #available(iOS 15.0, *) {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding(32)

                if #available(iOS 16.0, *) {
                    // iOS 16+ with `buttonBorderShape`
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                    .buttonStyle(.borderedProminent)
                    .padding(32)
                } else {
                    // Fallback for iOS 15 without `buttonBorderShape`
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(32)
                }
            } else {
                // iOS < 15 - Basic fallback
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(32)
            }
        }
    }
}
