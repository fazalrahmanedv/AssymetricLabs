import SwiftUI
import QuizRepo

struct QuizSummaryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: QuizViewModel
    
    // Calculate overall score based on answered questions count.
    var answeredCount: Int { viewModel.answeredOptions.count }
    var totalQuestions: Int { viewModel.quizList.count }
    var scorePercentage: Double {
        totalQuestions > 0 ? (Double(answeredCount) / Double(totalQuestions)) * 100 : 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Gamified header
            VStack(spacing: 8) {
                Text("Quiz Completed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Score: \(answeredCount) / \(totalQuestions)")
                    .font(.title2)
                    .foregroundColor(.white)
                Text(String(format: "%.0f%%", scorePercentage))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
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
            .padding(.horizontal)
            
            // Quiz Summary List
            List {
                ForEach(0..<totalQuestions, id: \.self) { index in
                    Button(action: {
                        // Navigate back to the quiz view at the selected question.
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
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Quiz Summary")
    }
    
    // Returns a status string for a question based on its persisted state.
    private func status(for index: Int) -> String {
        if viewModel.answeredOptions[index] != nil {
            return "Answered"
        } else if viewModel.bookmarkStates[index] == true {
            return "Bookmarked"
        } else {
            return "Unanswered"
        }
    }
    
    // Color-coding for status.
    private func color(for index: Int) -> Color {
        if viewModel.answeredOptions[index] != nil {
            return .green
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
    
    // Return an icon name based on status.
    private func icon(for index: Int) -> String {
        if viewModel.answeredOptions[index] != nil {
            return "checkmark.seal.fill"
        } else if viewModel.bookmarkStates[index] == true {
            return "bookmark.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
    
    // Icon color based on status.
    private func iconColor(for index: Int) -> Color {
        if viewModel.answeredOptions[index] != nil {
            return .green
        } else if viewModel.bookmarkStates[index] == true {
            return .yellow
        } else {
            return .red
        }
    }
}
