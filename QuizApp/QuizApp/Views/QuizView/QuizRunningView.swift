import SwiftUI
import QuizRepo
import WebKit
import AVFoundation
// MARK: - Main Quiz View
struct QuizView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel: QuizViewModel
    @State private var navigateToSummary = false
    @State private var showPositiveFeedback = false
    let optionLabels = ["A", "B", "C", "D"]
    var isFromBookmark = false
    init(quizList: [Quiz], isFromBookmarks: Bool) {
        _viewModel = StateObject(wrappedValue: QuizViewModel(quizList: quizList))
        self.isFromBookmark = isFromBookmarks
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    QuizProgressView(
                        maxIndex: viewModel.maxIndexReached,
                        totalQuestions: viewModel.quizList.count
                    )
                    .padding(.top)
                    ScrollView {
                        VStack(spacing: 12) {
                            if geometry.size.width > geometry.size.height {
                                LandscapeLayout(
                                    viewModel: viewModel,
                                    geometry: geometry,
                                    optionLabels: optionLabels,
                                    showPositiveFeedback: $showPositiveFeedback
                                )
                            } else {
                                PortraitLayout(
                                    viewModel: viewModel,
                                    geometry: geometry,
                                    optionLabels: optionLabels,
                                    showPositiveFeedback: $showPositiveFeedback
                                )
                            }
                            Spacer(minLength: 60) // Space for bottom controls
                        }
                    }
                    Spacer()
                }
                VStack {
                    BottomControls(
                        viewModel: viewModel,
                        onNext: {
                            viewModel.answerSubmitted = true
                            if viewModel.currentIndex == viewModel.quizList.count - 1 {
                                viewModel.pauseTimerForCurrentQuestion()
                                navigateToSummary = true
                            } else {
                                viewModel.nextQuestion()
                            }
                        },
                        onBack: {
                            viewModel.previousQuestion()
                        }
                    )
                    .background(Color(.systemBackground))
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
            }
            .overlay(
                Group {
                    if showPositiveFeedback {
                        FeedbackView()
                            .transition(.scale)
                    }
                }
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            if isFromBookmark{
                Task{
                    await viewModel.fetchBookmarkedQuestions()
                    viewModel.loadCurrentState()
                }
            } else {
                viewModel.loadCurrentState()
            }
        }
        .onDisappear {
            AudioPlayer.shared.stopAllSounds()
        }
        .onReceive(viewModel.timer) { _ in
            viewModel.updateTimer()
        }
        .navigationBarTitle("Quiz", displayMode: .inline)
        .navigationBarItems(trailing:
            BookmarkButton(
                isBookmarked: viewModel.bookmarkedQuestions.contains(viewModel.currentIndex),
                action: { viewModel.toggleBookmark() }
            )
        )
        .background(
            NavigationLink(
                destination: QuizSummaryView(viewModel: viewModel),
                isActive: $navigateToSummary,
                label: { EmptyView() }
            )
        )
    }
}

// MARK: - Portrait Layout
struct PortraitLayout: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy
    let optionLabels: [String]
    @Binding var showPositiveFeedback: Bool

    func optionText(for index: Int) -> String {
        guard let quiz = viewModel.currentQuestion else { return "" }
        switch index {
        case 0: return quiz.option1 ?? ""
        case 1: return quiz.option2 ?? ""
        case 2: return quiz.option3 ?? ""
        case 3: return quiz.option4 ?? ""
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Display question content based on type.
            if let question = viewModel.currentQuestion {
                if question.questiionType == "htmlText" {
                    if let html = question.question {
                        HTMLTextView(htmlContent: html)
                            .padding(8)
                    } else {
                        Text("HTML content not available")
                            .foregroundColor(.red)
                            .padding(8)
                    }
                } else if question.questiionType == "text" {
                    Text(question.question ?? "")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .frame(width: geometry.size.width * 0.95)
                        .transition(.slide)
                        .animation(.easeInOut, value: viewModel.currentIndex)
                } else if question.questiionType == "image" {
                    if let urlString = question.question {
                        if ImageCache.shared.image(forKey: urlString) != nil {
                            CachedImageView(urlString: urlString)
                        } else {
                            ProgressView()
                                .frame(width: 200, height: 200)
                        }
                    }
                } else {
                    Text(question.questiionType ?? "unknown")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .frame(width: geometry.size.width * 0.95)
                        .transition(.slide)
                        .animation(.easeInOut, value: viewModel.currentIndex)
                }
            }
            
            // Answer buttons.
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    AnswerButton(
                        index: index,
                        label: optionLabels[index],
                        answerText: optionText(for: index),
                        selectedAnswer: $viewModel.selectedAnswer,
                        isDisabled: $viewModel.isAnswerDisabled,
                        answerSubmitted: viewModel.answerSubmitted,
                        correctOption: viewModel.currentQuestion.map { Int($0.correctOption) },
                        onOptionSelected: { selected in
                            viewModel.selectAnswer(selected)
                            viewModel.pauseTimerForCurrentQuestion() // Pause timer on selection
                            let isCorrect = viewModel.currentQuestion.map({ Int($0.correctOption) }) == selected
                            AudioPlayer.shared.playSound(forCorrectAnswer: isCorrect)
                            if isCorrect {
                                showPositiveFeedback = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showPositiveFeedback = false
                                    }
                                }
                            }
                        }
                    )
                }
            }
            .padding(8)
            
            if viewModel.answerSubmitted {
                SolutionView(
                    solution: viewModel.currentQuestion?.solution,
                    width: geometry.size.width * 0.95
                )
            }
        }
    }
}

// MARK: - Landscape Layout
struct LandscapeLayout: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy
    let optionLabels: [String]
    @Binding var showPositiveFeedback: Bool

    func optionText(for index: Int) -> String {
        guard let quiz = viewModel.currentQuestion else { return "" }
        switch index {
        case 0: return quiz.option1 ?? ""
        case 1: return quiz.option2 ?? ""
        case 2: return quiz.option3 ?? ""
        case 3: return quiz.option4 ?? ""
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let question = viewModel.currentQuestion {
                            if question.questiionType == "htmlText" {
                                if let html = question.question {
                                    HTMLTextView(htmlContent: html)
                                        .padding(8)
                                } else {
                                    Text("HTML content not available")
                                        .foregroundColor(.red)
                                        .padding(8)
                                }
                            } else if question.questiionType == "text" {
                                Text(question.question ?? "")
                                    .font(.title3)
                                    .multilineTextAlignment(.leading)
                                    .padding(8)
                                    .transition(.slide)
                                    .animation(.easeInOut, value: viewModel.currentIndex)
                                    .layoutPriority(1) // <-- Ensures proper resizing
                            } else if question.questiionType == "image" {
                                if let urlString = question.question {
                                    if ImageCache.shared.image(forKey: urlString) != nil {
                                        CachedImageView(urlString: urlString)
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        ProgressView()
                                            .frame(width: 200, height: 200)
                                    }
                                }
                            } else {
                                Text(question.questiionType ?? "unknown")
                                    .font(.title3)
                                    .multilineTextAlignment(.leading)
                                    .padding(8)
                                    .transition(.slide)
                                    .animation(.easeInOut, value: viewModel.currentIndex)
                            }
                        }
                        
                        // Landscape answer options.
                        LandscapeAnswerOptionsView(
                            viewModel: viewModel,
                            geometry: geometry,
                            optionLabels: optionLabels,
                            showPositiveFeedback: $showPositiveFeedback
                        )
                        Spacer(minLength: 8)
                    }
                    .padding(.bottom, 40)
                }
            }
            .frame(width: geometry.size.width * 0.6) // <-- Adjust width properly
            
            if viewModel.answerSubmitted {
                SolutionView(
                    solution: viewModel.currentQuestion?.solution,
                    width: geometry.size.width * 0.4 // <-- Adjust width so it doesn't push out
                )
                .frame(maxHeight: geometry.size.height * 0.9) // <-- Prevents UI breaking
            }
        }
    }
}
struct LandscapeAnswerOptionsView: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy
    let optionLabels: [String]
    @Binding var showPositiveFeedback: Bool
    func optionText(for index: Int) -> String {
        guard let quiz = viewModel.currentQuestion else { return "" }
        switch index {
        case 0: return quiz.option1 ?? ""
        case 1: return quiz.option2 ?? ""
        case 2: return quiz.option3 ?? ""
        case 3: return quiz.option4 ?? ""
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                AnswerButton(
                    index: index,
                    label: optionLabels[index],
                    answerText: optionText(for: index),
                    selectedAnswer: $viewModel.selectedAnswer,
                    isDisabled: $viewModel.isAnswerDisabled,
                    answerSubmitted: viewModel.answerSubmitted,
                    correctOption: viewModel.currentQuestion.map { Int($0.correctOption) },
                    onOptionSelected: { selected in
                        viewModel.selectAnswer(selected)
                        viewModel.pauseTimerForCurrentQuestion() // Pause timer on selection
                        let isCorrect = viewModel.currentQuestion.map({ Int($0.correctOption) }) == selected
                        AudioPlayer.shared.playSound(forCorrectAnswer: isCorrect)
                        if isCorrect {
                            showPositiveFeedback = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showPositiveFeedback = false
                                }
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 50) // <-- Ensures proper layout
            }
        }
        .padding(.horizontal, 8)
    }
}
