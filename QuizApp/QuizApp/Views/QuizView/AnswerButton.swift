import SwiftUI

struct AnswerButton: View {
    let index: Int
    let label: String
    let answerText: String
    @Binding var selectedAnswer: Int?
    @Binding var isDisabled: Bool
    let answerSubmitted: Bool
    let correctOption: Int?
    let onOptionSelected: (Int) -> Void
    
    var body: some View {
        // Determine background color based on selection and correctness.
        let backgroundColor: Color = {
            if answerSubmitted {
                // When submitted, highlight correct answer in green.
                if let correct = correctOption {
                    if index == correct {
                        return Color.green
                    } else if selectedAnswer == index && index != correct {
                        return Color.red
                    } else {
                        return Color.gray.opacity(0.7)
                    }
                } else {
                    return Color.gray.opacity(0.7)
                }
            } else {
                // Before submission, show the selected option in blue.
                return selectedAnswer == index ? Color.blue.opacity(0.8) : Color.gray.opacity(0.7)
            }
        }()
        
        return Button(action: {
            if !isDisabled {
                // When tapped, notify the view model.
                onOptionSelected(index)
                // Trigger haptic feedback.
                if let correct = correctOption {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(index == correct ? .success : .error)
                }
            }
        }) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                Text(answerText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.leading, 6)
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .disabled(isDisabled)
        .animation(.easeInOut, value: selectedAnswer)
    }
}

struct AnswerButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Default state: not selected, not submitted.
            AnswerButton(
                index: 0,
                label: "A",
                answerText: "Option A",
                selectedAnswer: .constant(nil),
                isDisabled: .constant(false),
                answerSubmitted: false,
                correctOption: 1,
                onOptionSelected: { _ in }
            )
            .previewDisplayName("Default State")
            
            // Submitted and correct answer.
            AnswerButton(
                index: 1,
                label: "B",
                answerText: "Option B",
                selectedAnswer: .constant(1),
                isDisabled: .constant(true),
                answerSubmitted: true,
                correctOption: 1,
                onOptionSelected: { _ in }
            )
            .previewDisplayName("Submitted & Correct")
            
            // Submitted with an incorrect answer.
            AnswerButton(
                index: 0,
                label: "A",
                answerText: "Option A",
                selectedAnswer: .constant(0),
                isDisabled: .constant(true),
                answerSubmitted: true,
                correctOption: 1,
                onOptionSelected: { _ in }
            )
            .previewDisplayName("Submitted & Incorrect")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
