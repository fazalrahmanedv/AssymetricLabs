import SwiftUI
import Lottie
import AVFoundation

struct QuizSummaryView: View {
    @Environment(\.presentationMode) var presentationMode // ✅ iOS 14+ Compatible
    @ObservedObject var viewModel: QuizViewModel
    var answeredCount: Int { viewModel.answeredOptions.count }
    var totalQuestions: Int { viewModel.quizList.count }
    var scorePercentage: Double { viewModel.scorePercentage }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // ✅ Score Header with Dynamic Animation
                scoreHeader()
                    .padding(.horizontal)
                
                // ✅ Quiz List Section
                quizList()
                    .padding(.horizontal)
            }
            .padding(.top)
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle("Quiz Summary")
        .onAppear {
            playSound()
        }
    }
    
    // ✅ Play Sound Based on Score
    func playSound() {
        if scorePercentage >= 60 {
            AudioPlayer.shared.playSound(forWon: true)
        } else {
            AudioPlayer.shared.playSound(forWon: false)
        }
    }
    
    // ✅ Score Header
    private func scoreHeader() -> some View {
        VStack(spacing: 12) {
            
            // ✅ Title
            Text("Quiz Completed!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // ✅ Score Text
            Text("Score: \(viewModel.totalCorrectAnswers * 100)")
                .font(.title2)
                .foregroundColor(.white)
            
            // ✅ Percentage
            Text(String(format: "%.0f%%", scorePercentage))
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundColor(scoreColor())
            
            // ✅ Celebration Animation if Score >= 80%
            if scorePercentage >= 80 {
                LottieCelebrationView(animationName: "Confetti")
                    .frame(width: 180, height: 180)
                    .padding(.top, -20)
            }
            
            // ✅ Share Score Button
            Button(action: shareScore) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                    Text("Share your score")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(scoreBackground())
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    // ✅ Quiz Summary List
    private func quizList() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review your questions")
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(0..<totalQuestions, id: \.self) { index in
                Button(action: {
                    viewModel.currentIndex = index
                    viewModel.loadCurrentState()
                    dismissView()
                }) {
                    HStack {
                        Image(systemName: icon(for: index))
                            .foregroundColor(iconColor(for: index))
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("Question \(index + 1)")
                                .font(.headline)
                            
                            Text(status(for: index))
                                .font(.subheadline)
                                .foregroundColor(color(for: index))
                        }
                        
                        Spacer()
                        Text("Remaining time: \(viewModel.remainingTimes[index] ?? 60)s")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // ✅ Status for each question
    private func status(for index: Int) -> String {
        if let currentQuestion = viewModel.answeredOptions[index]{
            if  currentQuestion == viewModel.quizList[index].correctOption {
                return "Correct!"
            } else {
                return "Wronng!"
            }
        } else if viewModel.bookmarkStates[index] == true {
            return "Bookmarked"
        } else {
            return "Unanswered"
        }
    }
    
    // ✅ Icon for each question
    private func icon(for index: Int) -> String {
        if let currentQuestion = viewModel.answeredOptions[index]{
            if  currentQuestion == viewModel.quizList[index].correctOption {
                return "checkmark.seal.fill"
            }  else {
                return "xmark.circle.fill"
            }
        } else if viewModel.bookmarkStates[index] == true {
            return "bookmark.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    // ✅ Icon Color
    private func iconColor(for index: Int) -> Color {
        if let currentQuestion = viewModel.answeredOptions[index]{
            if  currentQuestion == viewModel.quizList[index].correctOption {
                return .green
            } else {
                return .red
            }
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
    
    // ✅ Text Color
    private func color(for index: Int) -> Color {
        if let currentQuestion = viewModel.answeredOptions[index]{
            if  currentQuestion == viewModel.quizList[index].correctOption {
                return .green
            } else {
                return .red
            }
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
    
    // ✅ Share Button Action
    private func shareScore() {
        let scoreText = "I scored \(viewModel.totalCorrectAnswers * 100) points in the quiz! 🏆 Can you beat my score?"
        let activityController = UIActivityViewController(activityItems: [scoreText], applicationActivities: nil)
        
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityController, animated: true, completion: nil)
        }
    }
    
    // ✅ Background Color Based on Score
    private func scoreBackground() -> LinearGradient {
        if scorePercentage >= 80 {
            return LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
        } else if scorePercentage >= 50 {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.red, .purple], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    // ✅ Score Text Color
    private func scoreColor() -> Color {
        if scorePercentage >= 80 {
            return .green
        } else if scorePercentage >= 50 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // ✅ Dismiss View (Support for iOS 14+)
    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }
}

// ✅ Lottie Celebration View
struct LottieCelebrationView: UIViewRepresentable {
    var animationName: String
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.play()
        
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
