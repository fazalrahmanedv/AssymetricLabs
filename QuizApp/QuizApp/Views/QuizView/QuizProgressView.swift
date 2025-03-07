import SwiftUI
struct QuizProgressView: View {
    let maxIndex: Int
    let totalQuestions: Int
    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(maxIndex + 1) / Double(totalQuestions)
    }
    var body: some View {
        VStack {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            Text("Question \(maxIndex + 1)/\(totalQuestions)")
                .font(.footnote)
                .padding(.top, 4)
        }
    }
}
struct QuizProgressView_Previews: PreviewProvider {
    static var previews: some View {
        QuizProgressView(maxIndex: 0, totalQuestions: 5)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
