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
        Group {
//            if #available(iOS 16.0, *) {
//                NavigationStack {
//                    contentView
//                }
//            } else {
//                NavigationView {
                    contentView
//                }
//            }
        }
    }
    // Inside contentView
    private var contentView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack {
                    QuizProgressView(
                        maxIndex: viewModel.maxIndexReached,
                        totalQuestions: viewModel.quizList.count
                    )
                    .padding(.top)
                    scrollViewContent(geometry: geometry)
                    Spacer(minLength: 60) // Space for bottom controls
                }
                bottomControls
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                if isFromBookmark {
                    Task {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    BookmarkButton(
                        isBookmarked: viewModel.bookmarkedQuestions.contains(viewModel.currentIndex),
                        action: { viewModel.toggleBookmark() }
                    )
                }
            }
            
            // ✅ FeedbackView placed as top-most
            if showPositiveFeedback {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    FeedbackView()
                        .transition(.scale)
                        .zIndex(2) // Ensures FeedbackView is on top
                }
            }
            
            if #available(iOS 16.0, *) {
                navigationLinkView
            } else {
                legacyNavigationLink
            }
        }
    }


    // MARK: - Scroll View Handling
    @ViewBuilder
    private func scrollViewContent(geometry: GeometryProxy) -> some View {
        if #available(iOS 16.4, *) {
            ScrollView {
                scrollViewContentInternal(geometry: geometry)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView {
                scrollViewContentInternal(geometry: geometry)
            }
        }
    }

    private func scrollViewContentInternal(geometry: GeometryProxy) -> some View {
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
        }
        .padding(8)
    }

    // MARK: - Bottom Controls
    private var bottomControls: some View {
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

    // MARK: - Navigation Handling (iOS 16+)
    @ViewBuilder
    private var navigationLinkView: some View {
        NavigationLink(destination: QuizSummaryView(viewModel: viewModel), isActive: $navigateToSummary) {
            EmptyView()
        }
        .hidden()
    }

    // MARK: - Navigation Handling (iOS 14/15)
    @ViewBuilder
    private var legacyNavigationLink: some View {
        NavigationLink(
            destination: QuizSummaryView(viewModel: viewModel),
            isActive: $navigateToSummary
        ) {
            EmptyView()
        }
        .hidden()
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
            QuestionContentView(viewModel: viewModel, geometry: geometry)
            answerOptions
            if viewModel.answerSubmitted {
                SolutionView(
                    solution: viewModel.currentQuestion?.solution,
                    width: geometry.size.width * 0.95
                )
            }
        }
    }

    private var answerOptions: some View {
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
                        handleAnswerSelection(selected)
                    }
                )
            }
        }
        .padding(8)
    }

    private func handleAnswerSelection(_ selected: Int) {
        viewModel.selectAnswer(selected)
        viewModel.pauseTimerForCurrentQuestion()
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
}

// MARK: - Landscape Layout
struct LandscapeLayout: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy
    let optionLabels: [String]
    @Binding var showPositiveFeedback: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        QuestionContentView(viewModel: viewModel, geometry: geometry)
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
            .frame(width: geometry.size.width * 0.6)

            if viewModel.answerSubmitted {
                SolutionView(
                    solution: viewModel.currentQuestion?.solution,
                    width: geometry.size.width * 0.4
                )
                .frame(maxHeight: geometry.size.height * 0.9)
            }
        }
    }
}

// MARK: - Question Content View
struct QuestionContentView: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy

    var body: some View {
        if let question = viewModel.currentQuestion {
            switch question.questiionType {
            case "htmlText":
                HTMLTextView(htmlContent: question.question ?? "HTML content not available")
                    .padding(8)
            case "text":
                Text(question.question ?? "")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(width: geometry.size.width * 0.95)
                    .transition(.slide)
                    .animation(.easeInOut, value: viewModel.currentIndex)
            case "image":
                if let urlString = question.question {
                    if ImageCache.shared.image(forKey: urlString) != nil {
                        CachedImageView(urlString: urlString)
                    } else {
                        ProgressView()
                            .frame(width: 200, height: 200)
                    }
                }
            default:
                Text(question.questiionType ?? "unknown")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(width: geometry.size.width * 0.95)
                    .transition(.slide)
                    .animation(.easeInOut, value: viewModel.currentIndex)
            }
        }
    }
}

// MARK: - Landscape Answer Options
struct LandscapeAnswerOptionsView: View {
    @ObservedObject var viewModel: QuizViewModel
    var geometry: GeometryProxy
    let optionLabels: [String]
    @Binding var showPositiveFeedback: Bool

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
                        handleAnswerSelection(selected)
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 50)
            }
        }
        .padding(.horizontal, 8)
    }

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

    private func handleAnswerSelection(_ selected: Int) {
        viewModel.selectAnswer(selected)
        viewModel.pauseTimerForCurrentQuestion()
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
}
