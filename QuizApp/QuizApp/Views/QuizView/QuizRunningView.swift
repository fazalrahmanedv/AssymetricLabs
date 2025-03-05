//
//  QuizView.swift
//

import SwiftUI
import QuizRepo
import WebKit

struct QuizView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var timeRemaining = 60
    @State private var selectedAnswer: Int? = nil
    @State private var questionIndex = 0
    @State private var bookmarkedQuestions = Set<Int>()
    @State private var isAnswerDisabled = false
    @State private var showTimeoutOverlay = false
    @State private var answerSubmitted = false
    @State private var isTimerActive = true
    @State var questions: [Quiz] = []  // Nonoptional array of Quiz
    let optionLabels = ["A", "B", "C", "D"]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Fixed header/footer heights.
    private let headerHeight: CGFloat = 50
    private let footerHeight: CGFloat = 60
    
    var backgroundGradient: LinearGradient {
        let startPoint: UnitPoint = .topLeading
        let endPoint: UnitPoint = .bottomTrailing
        if colorScheme == .dark {
            let colors = [
                Color(red: 14/255, green: 28/255, blue: 38/255),
                Color(red: 42/255, green: 69/255, blue: 75/255),
                Color(red: 41/255, green: 72/255, blue: 97/255)
            ]
            return LinearGradient(gradient: Gradient(colors: colors),
                                  startPoint: startPoint,
                                  endPoint: endPoint)
        } else {
            let colors = [
                Color(red: 202/255, green: 208/255, blue: 255/255),
                Color(red: 224/255, green: 230/255, blue: 255/255),
                Color(red: 227/255, green: 227/255, blue: 227/255)
            ]
            return LinearGradient(gradient: Gradient(colors: colors),
                                  startPoint: startPoint,
                                  endPoint: endPoint)
        }
    }
    
    // Computed solution message based on user selection.
    var solutionMessage: String {
        guard let selected = selectedAnswer,
              let currentQuiz = questions[safe: questionIndex] else {
            return ""
        }
        let correctness = (selected == Int(currentQuiz.correctOption)) ? "Correct!" : "Incorrect!"
        return "\(correctness) \(currentQuiz.solution?.contentData ?? "No solution available.")"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundGradient.ignoresSafeArea()
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 12) {
                        Color.clear.frame(height: headerHeight)
                        if geometry.size.width > geometry.size.height {
                            landscapeLayout(in: geometry)
                        } else {
                            portraitLayout(in: geometry)
                        }
                        Color.clear.frame(height: footerHeight)
                    }
                }
                
                // Fixed top and bottom bars
                topBar(in: geometry)
                bottomBar(in: geometry)
            }
            .onReceive(timer) { _ in
                updateTime()
            }
        }
    }
    
    // Helper function to retrieve option text from the current quiz.
    func optionText(for index: Int, quiz: Quiz?) -> String {
        guard let quiz = quiz else { return "" }
        switch index {
        case 0: return quiz.option1 ?? ""
        case 1: return quiz.option2 ?? ""
        case 2: return quiz.option3 ?? ""
        case 3: return quiz.option4 ?? ""
        default: return ""
        }
    }
    
    // MARK: - Layout Methods
    
    func portraitLayout(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Display question content based on its type.
            if questions[safe: questionIndex]?.questiionType == "htmlText" {
                if let html = questions[safe: questionIndex]?.question {
                    HTMLTextView(htmlContent: html)
                        .padding(8)
                } else {
                    Text("HTML content not available")
                        .foregroundColor(.red)
                        .padding(8)
                }
            } else if questions[safe: questionIndex]?.questiionType == "text" {
                Text(questions[safe: questionIndex]?.question ?? "")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(width: geometry.size.width * 0.95)
                    .transition(.slide)
                    .animation(.easeInOut, value: questionIndex)
            } else if questions[safe: questionIndex]?.questiionType == "image" {
                if let urlString = questions[safe: questionIndex]?.question {
                    if ImageCache.shared.image(forKey: urlString) != nil {
                        CachedImageView(urlString: urlString)
                    } else {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    }
                }
            } else {
                Text(questions[safe: questionIndex]?.questiionType ?? "unknown")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(width: geometry.size.width * 0.95)
                    .transition(.slide)
                    .animation(.easeInOut, value: questionIndex)
            }
            
            // Answer buttons with option-click logic.
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    AnswerButton(
                        index: index,
                        label: optionLabels[index],
                        answerText: optionText(for: index, quiz: questions[safe: questionIndex]),
                        selectedAnswer: $selectedAnswer,
                        isDisabled: $isAnswerDisabled,
                        answerSubmitted: answerSubmitted,
                        correctOption: questions[safe: questionIndex].map { Int($0.correctOption) },
                        onOptionSelected: { selected in
                            answerSubmitted = true
                            isAnswerDisabled = true
                            isTimerActive = false  // Stop timer
                        }
                    )
                }
            }
            .padding(8)
            
            // Show solution only after an answer is submitted.
            if answerSubmitted {
                solutionView(width: geometry.size.width * 0.95)
            }
        }
    }
    
    func landscapeLayout(in geometry: GeometryProxy) -> some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if questions[safe: questionIndex]?.questiionType == "htmlText" {
                            if let html = questions[safe: questionIndex]?.question {
                                HTMLTextView(htmlContent: html)
                                    .padding(8)
                            } else {
                                Text("HTML content not available")
                                    .foregroundColor(.red)
                                    .padding(8)
                            }
                        } else if questions[safe: questionIndex]?.questiionType == "text" {
                            Text(questions[safe: questionIndex]?.question ?? "")
                                .font(.title3)
                                .multilineTextAlignment(.leading)
                                .padding(8)
                                .transition(.slide)
                                .animation(.easeInOut, value: questionIndex)
                        } else if questions[safe: questionIndex]?.questiionType == "image" {
                            if let urlString = questions[safe: questionIndex]?.question {
                                if ImageCache.shared.image(forKey: urlString) != nil {
                                    CachedImageView(urlString: urlString)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    ProgressView()
                                        .frame(width: 200, height: 200)
                                }
                            }
                        } else {
                            Text(questions[safe: questionIndex]?.questiionType ?? "unknown")
                                .font(.title3)
                                .multilineTextAlignment(.leading)
                                .padding(8)
                                .transition(.slide)
                                .animation(.easeInOut, value: questionIndex)
                        }
                        
                        // Landscape answer options.
                        landscapeAnswerOptionsView(geometry: geometry)
                        Spacer(minLength: 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .frame(width: geometry.size.width * 0.6)
            
            // Show solution on the side if an answer has been submitted.
            if answerSubmitted {
                solutionView(width: geometry.size.width * 0.35)
                    .padding(8)
            }
        }
    }
    
    func landscapeAnswerOptionsView(geometry: GeometryProxy) -> some View {
        let optionMinHeight = max(40, geometry.size.height * 0.1)
        return VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                landscapeOptionView(for: index, optionMinHeight: optionMinHeight)
            }
        }
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private func landscapeOptionView(for index: Int, optionMinHeight: CGFloat) -> some View {
        // Use the same AnswerButton with the updated parameters.
        AnswerButton(
            index: index,
            label: optionLabels[index],
            answerText: optionText(for: index, quiz: questions[safe: questionIndex]),
            selectedAnswer: $selectedAnswer,
            isDisabled: $isAnswerDisabled,
            answerSubmitted: answerSubmitted,
            correctOption: questions[safe: questionIndex].map { Int($0.correctOption) },
            onOptionSelected: { selected in
                answerSubmitted = true
                isAnswerDisabled = true
                isTimerActive = false
            }
        )
        .frame(minHeight: optionMinHeight)
    }
    
    func solutionView(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Solution")
                .font(.subheadline)
                .padding(.horizontal, 8)
            ScrollView {
                Text(solutionMessage)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: width)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    func topBar(in geometry: GeometryProxy) -> some View {
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
    }
    
    func bottomBar(in geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()
            bottomControls
                .background(Color(.systemBackground).opacity(0.5))
                .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - Fixed Controls
    
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
            answerSubmitted = false
            isTimerActive = true
            bookmarkedQuestions.removeAll()
        }) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
        }
    }
    
    var bottomControls: some View {
        HStack {
            Button(action: {
                if questionIndex > 0 {
                    questionIndex -= 1
                    selectedAnswer = nil
                    timeRemaining = 60
                    isAnswerDisabled = false
                    answerSubmitted = false
                    isTimerActive = true
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 36, height: 36)
                    Text("Back")
                }
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
                // Move to the next question and reset state.
                if questionIndex < questions.count - 1 {
                    questionIndex += 1
                    selectedAnswer = nil
                    timeRemaining = 60
                    isAnswerDisabled = false
                    answerSubmitted = false
                    isTimerActive = true
                }
            }) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 36, height: 36)
                }
            }
        }
    }
    
    // MARK: - Timer Update
    
    private func updateTime() {
        guard isTimerActive else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else if !showTimeoutOverlay {
            isAnswerDisabled = true
            showTimeoutOverlay = true
            isTimerActive = false
        }
    }
}

// A custom button view for answer options.
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
        // Determine background color based on answer submission and correctness.
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
                return (selectedAnswer == index ? Color.blue.opacity(0.8) : Color.gray.opacity(0.7))
            }
        }()
        
        return Button(action: {
            if !isDisabled {
                selectedAnswer = index
                onOptionSelected(index)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    // Optionally, you can adjust the circle fill here as well.
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

// Safe subscript extension to prevent index-out-of-range errors.
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        QuizView()
    }
}

extension AttributedString {
    init?(html: String) {
        guard let data = html.data(using: .utf8) else { return nil }
        if let nsAttrString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil) {
            self.init(nsAttrString)
        } else {
            return nil
        }
    }
}

struct HTMLTextView: View {
    let htmlContent: String
    var body: some View {
        if let attributedString = AttributedString(html: htmlContent) {
            Text(attributedString)
                .padding()
        } else {
            Text("Unable to load content.")
        }
    }
}

struct CachedImageView: View {
    let urlString: String
    var body: some View {
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            Image(uiImage: cachedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            ProgressView()
                .frame(width: 200, height: 200)
        }
    }
}
