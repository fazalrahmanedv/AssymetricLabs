import SwiftUI

struct QuizView: View {
    @Environment(\.colorScheme) var colorScheme

    @State private var timeRemaining = 60
    @State private var selectedAnswer: Int? = nil
    @State private var questionIndex = 0
    @State private var bookmarkedQuestions = Set<Int>()
    @State private var isAnswerDisabled = false
    @State private var showTimeoutOverlay = false

    let questions = [
        ("What is the capital of France?", ["Paris", "Berlin", "London", "Madrid"]),
        ("Which planet is known as the Red Planet?", ["Earth", "Mars", "Jupiter", "Venus"]),
        ("Who wrote 'Hamlet'?", ["Shakespeare", "Hemingway", "Tolstoy", "Dostoevsky"]),
        ("What is the square root of 64?", ["6", "7", "8", "9"]),
        ("Which element has the chemical symbol 'O'?", ["Gold", "Oxygen", "Silver", "Iron"])
    ]
    let optionLabels = ["A", "B", "C", "D"]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Fixed header/footer heights.
    private let headerHeight: CGFloat = 50
    private let footerHeight: CGFloat = 60

    var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 14/255, green: 28/255, blue: 38/255),
                    Color(red: 42/255, green: 69/255, blue: 75/255),
                    Color(red: 41/255, green: 72/255, blue: 97/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 202/255, green: 208/255, blue: 255/255),
                    Color(red: 224/255, green: 230/255, blue: 255/255),
                    Color(red: 227/255, green: 227/255, blue: 227/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Main scrollable content.
                ScrollView {
                    VStack(spacing: 12) {
                        // Spacer for fixed top bar.
                        Color.clear.frame(height: headerHeight)
                        
                        if geometry.size.width > geometry.size.height {
                            // Landscape layout.
                            HStack(spacing: 8) {
                                VStack(spacing: 8) {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(questions[questionIndex].0)
                                                .font(.title3)
                                                .multilineTextAlignment(.leading)
                                                .padding(.horizontal, 8)
                                            answerOptions(in: geometry)
                                            Spacer(minLength: 8)
                                        }
                                        .padding(.bottom, 40)
                                    }
//                                    bottomControls
//                                        .padding(.horizontal, 8)
//                                        .padding(.vertical, 4)
                                }
                                .frame(width: geometry.size.width * 0.6)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Solution")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                    ScrollView {
                                        Text("Solution details will appear here in the future.")
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(width: geometry.size.width * 0.35)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        } else {
                            // Portrait layout.
                            VStack(spacing: 12) {
                                Text(questions[questionIndex].0)
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .padding(8)
                                    .frame(width: geometry.size.width * 0.95)
                                    .transition(.slide)
                                    .animation(.easeInOut, value: questionIndex)
                                
                                VStack(spacing: 8) {
                                    ForEach(0..<4, id: \.self) { index in
                                        Button(action: {
                                            if !isAnswerDisabled {
                                                selectedAnswer = index
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                            }
                                        }) {
                                            HStack {
                                                Text(optionLabels[index])
                                                    .font(.subheadline)
                                                    .foregroundColor(.white)
                                                    .frame(width: 30, height: 30)
                                                    .background(Circle().fill(selectedAnswer == index ? Color.blue : Color.gray))
                                                
                                                Text(questions[questionIndex].1[index])
                                                    .font(.body)
                                                    .foregroundColor(.white)
                                                    .padding(.leading, 6)
                                                
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .frame(maxWidth: .infinity, minHeight: 40)
                                            .background(selectedAnswer == index ? Color.blue.opacity(0.8) : Color.gray.opacity(0.7))
                                            .cornerRadius(8)
                                        }
                                        .disabled(isAnswerDisabled)
                                        .animation(.easeInOut, value: selectedAnswer)
                                    }
                                }
                                .padding(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Solution")
                                        .font(.subheadline)
                                        .padding(.horizontal, 8)
                                    ScrollView {
                                        Text("Solution details will appear here in the future.")
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(width: geometry.size.width * 0.95)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
//                                Spacer()
                            }
                        }
                        
                        // Spacer for fixed bottom bar.
                        Color.clear.frame(height: footerHeight)
                    }
                }
                
                // Fixed transparent top bar.
                VStack {
                    HStack(spacing: 8) {
                        Spacer()
                        bookmarkButton
                        resetButton
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 4)
                    .padding(.horizontal, 8)
                    .frame(height: headerHeight)
                    .background(Color.clear)
                    .ignoresSafeArea(edges: .top)
                    Spacer()
                }
                
                // Fixed bottom bar.
                VStack {
                    Spacer()
                    bottomControls
//                        .frame(height: footerHeight)
//                        .padding(.horizontal, 8)
//                        .padding(.bottom, geometry.safeAreaInsets.bottom + 4)
                        .background(Color(.systemBackground).opacity(0.5))
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .background(backgroundGradient.ignoresSafeArea())
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else if !showTimeoutOverlay {
                    isAnswerDisabled = true
                    showTimeoutOverlay = true
                }
            }
        }
    }
    
    // MARK: - Extracted Views
    
    var bookmarkButton: some View {
        Button(action: {
            if bookmarkedQuestions.contains(questionIndex) {
                bookmarkedQuestions.remove(questionIndex)
            } else {
                bookmarkedQuestions.insert(questionIndex)
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            Image(systemName: bookmarkedQuestions.contains(questionIndex) ? "bookmark.fill" : "bookmark")
                .foregroundColor(bookmarkedQuestions.contains(questionIndex) ? .yellow : .gray)
                .font(.title3)
        }
    }
    
    var resetButton: some View {
        Button(action: {
            questionIndex = 0
            selectedAnswer = nil
            timeRemaining = 60
            isAnswerDisabled = false
            bookmarkedQuestions.removeAll()
        }) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
        }
    }
    
    func answerOptions(in geometry: GeometryProxy) -> some View {
        let optionMinHeight = max(40, geometry.size.height * 0.1)
        return VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Button(action: {
                    if !isAnswerDisabled {
                        selectedAnswer = index
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }) {
                    HStack {
                        Text(optionLabels[index])
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(selectedAnswer == index ? Color.blue : Color.gray))
                        
                        Text(questions[questionIndex].1[index])
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.leading, 6)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: optionMinHeight)
                    .background(selectedAnswer == index ? Color.blue.opacity(0.8) : Color.gray.opacity(0.7))
                    .cornerRadius(8)
                }
                .disabled(isAnswerDisabled)
                .animation(.easeInOut, value: selectedAnswer)
            }
        }
        .padding(.horizontal, 8)
    }
    
    var bottomControls: some View {
        HStack {
            Button(action: {
                if questionIndex > 0 {
                    questionIndex -= 1
                    selectedAnswer = nil
                    timeRemaining = 60
                    isAnswerDisabled = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
                Text("Back")
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(timeRemaining) / 60)
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
            Spacer()
            Button(action: {
                if questionIndex < questions.count - 1 {
                    questionIndex += 1
                    selectedAnswer = nil
                    timeRemaining = 60
                    isAnswerDisabled = false
                }
            }) {
                Text("Next")
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 36, height: 36)
            }
        }
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}
