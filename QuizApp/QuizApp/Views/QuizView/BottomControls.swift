import SwiftUI
import AVFoundation
struct TimerView: View {
    let timeRemaining: Int
    let totalDuration: Int
    var body: some View {
        ZStack {
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
            Circle()
                .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalDuration))
                .stroke(
                    AngularGradient(gradient: Gradient(colors: [.blue, .purple]), center: .center),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: timeRemaining)
            Text("\(timeRemaining)s")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .frame(width: 40, height: 40)
        .onChange(of: timeRemaining) { newValue in
            if newValue == 1 {
                AudioPlayer.shared.playTimeout()
            }
        }
    }
}
struct BottomControls: View {
    @ObservedObject var viewModel: QuizViewModel
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onBack()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            .disabled(viewModel.currentIndex == 0)
            Spacer()
            TimerView(timeRemaining: viewModel.timeRemaining,
                      totalDuration: viewModel.predictedTotalDuration)
            
            Spacer()
            
            Button(action: {
                onNext()
            }) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
    }
}
extension QuizViewModel {
    var predictedTotalDuration: Int {
        if let question = currentQuestion,
           question.questiionType == "text" || question.questiionType == "htmlText" {
            return Int(estimatedDuration(for: question))
        }
        return 60
    }
}
