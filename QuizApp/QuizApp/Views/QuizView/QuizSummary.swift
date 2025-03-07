import SwiftUI
import QuizRepo

struct QuizSummaryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: QuizViewModel
    
    var answeredCount: Int { viewModel.answeredOptions.count }
    var totalQuestions: Int { viewModel.quizList.count }
    var scorePercentage: Double {
        viewModel.scorePercentage
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            Group {
                if isLandscape {
                    HStack(spacing: 16) {
                        scoreHeader()
                            .frame(width: geometry.size.width * 0.4)
                        
                        quizList()
                            .frame(width: geometry.size.width * 0.6)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        scoreHeader()
                        quizList()
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Quiz Summary")
        }
    }
    
    // Gamified Score Header
    private func scoreHeader() -> some View {
           VStack(spacing: 8) {
               Text("Quiz Completed!")
                   .font(.largeTitle)
                   .fontWeight(.bold)
                   .foregroundColor(.white)
               
               Text("Score: \(viewModel.totalCorrectAnswers * 100)")
                   .font(.title2)
                   .foregroundColor(.white)
               
               Text(String(format: "%.0f%%", scorePercentage))
                   .font(.system(size: 48, weight: .heavy, design: .rounded))
                   .foregroundColor(.yellow)
               
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
           .background(
               LinearGradient(
                   gradient: Gradient(colors: [.blue, .purple]),
                   startPoint: .leading,
                   endPoint: .trailing
               )
           )
           .cornerRadius(12)
       }
    
    // Quiz Summary List
    private func quizList() -> some View {
        List {
            Section("You can answer any bookmarked or unanswered question here.", content: {
                ForEach(0..<totalQuestions, id: \.self) { index in
                    Button(action: {
                        viewModel.currentIndex = index
                        viewModel.loadCurrentState()
                        dismiss()
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
                            
                            Text("Time: \(viewModel.remainingTimes[index] ?? 60)s")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            })
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func status(for index: Int) -> String {
        if viewModel.answeredOptions[index] != nil {
            return "Answered"
        } else if viewModel.bookmarkStates[index] == true {
            return "Bookmarked"
        } else {
            return "Unanswered"
        }
    }
    
    private func color(for index: Int) -> Color {
        if viewModel.answeredOptions[index] != nil {
            return .green
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func icon(for index: Int) -> String {
        if viewModel.answeredOptions[index] != nil {
            return "checkmark.seal.fill"
        } else if viewModel.bookmarkStates[index] == true {
            return "bookmark.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func iconColor(for index: Int) -> Color {
        if viewModel.answeredOptions[index] != nil {
            return .green
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
    private func shareScore() {
        let scoreText = "I scored \(viewModel.totalCorrectAnswers * 100) points in the quiz! 🏆 Can you beat my score?"
        let activityController = UIActivityViewController(activityItems: [scoreText], applicationActivities: nil)
        if let topController = UIApplication.shared.windows.first?.rootViewController {
               topController.present(activityController, animated: true, completion: nil)
        }
    }
}

