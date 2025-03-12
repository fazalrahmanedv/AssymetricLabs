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
    
    @State private var shakeOffset: CGFloat = 0 // Shake animation offset

    var body: some View {
        // Determine background color based on selection and correctness.
        let backgroundColor: Color = {
            if answerSubmitted {
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
                return selectedAnswer == index ? Color.blue.opacity(0.8) : Color.gray.opacity(0.7)
            }
        }()
        
        return Button(action: {
            if !isDisabled {
                onOptionSelected(index)
                
                if let correct = correctOption {
                    let feedbackGenerator = UINotificationFeedbackGenerator()
                    feedbackGenerator.notificationOccurred(index == correct ? .success : .error)
                    
                    // Trigger shaking if the answer is wrong
                    if index != correct {
                        withAnimation(Animation.default.repeatCount(4, autoreverses: true)) {
                            shakeOffset = 2
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shakeOffset = 0
                        }
                    }
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
            .offset(x: shakeOffset) // Apply shaking effect
        }
        .disabled(isDisabled)
        .animation(.easeInOut, value: selectedAnswer)
    }
}
