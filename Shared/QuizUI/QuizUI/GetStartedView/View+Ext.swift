import SwiftUI
extension View {
	public func welcomeSheet(
		isPresented: Binding<Bool>,
		onDismiss: (() -> Void)?,
		rows: [OnboardingRow],
		title: LocalizedStringKey,
		actionTitle: LocalizedStringKey,
		onConfirm: @escaping () -> Void
	) -> some View {
         self.sheet(
			isPresented: isPresented,
			onDismiss: onDismiss) {
					 OnboardingView(
						title: title,
						rows: rows,
						actionTitle: actionTitle,
						action: onConfirm
					 )
        }
    }
}
