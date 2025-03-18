import SwiftUI
import Combine
import QuizRepo
import CoreML
import CoreData

class QuizViewModel: ObservableObject {
    @Published var currentIndex = 0
    @Published var maxIndexReached = 0  // Highest question index reached
    @Published var selectedAnswer: Int? = nil
    @Published var answerSubmitted = false
    @Published var isAnswerDisabled = false
    @Published var timeRemaining = 60
    @Published var isTimerActive = true
    @Published var bookmarkedQuestions = Set<Int>()
    @Published var isTimerPaused = false
    @Published var scrollResetID = UUID() // Unique ID to reset scroll position
    
    private let durationEstimator = QuestionDurationEstimator()
    private let coreDataStack = CoreDataStack.shared
    
    // Dictionaries to persist state for each question
    var answeredOptions: [Int: Int] = [:]
    var remainingTimes: [Int: Int] = [:]
    var bookmarkStates: [Int: Bool] = [:]
    
    @Published var quizList: [Quiz] = []
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(quizList: [Quiz]) {
        self.quizList = quizList
        // Initialize remaining time and bookmark state for every question.
        for index in 0..<quizList.count {
            let question = quizList[index]
            if question.questiionType == "text" || question.questiionType == "htmlText" {
                let estimated = Int(estimatedDuration(for: question))
                remainingTimes[index] = estimated
            } else {
                remainingTimes[index] = 60
            }
            bookmarkStates[index] = false
        }
    }
    
    var currentQuestion: Quiz? {
        quizList.indices.contains(currentIndex) ? quizList[currentIndex] : nil
    }
    
    var totalCorrectAnswers: Int {
        answeredOptions.filter { index, selectedAnswer in
            selectedAnswer == Int(quizList[index].correctOption)
        }.count
    }
    
    var scorePercentage: Double {
        let totalQuestions = quizList.count
        return totalQuestions > 0 ? (Double(totalCorrectAnswers) / Double(totalQuestions)) * 100 : 0
    }
    
    var solutionMessage: String {
        guard let selected = selectedAnswer,
              let question = currentQuestion else { return "" }
        let correct = Int(question.correctOption)
        let correctness = (selected == correct) ? "Correct!" : "Incorrect!"
        return "\(correctness) \(question.solution?.contentData ?? "No solution available.")"
    }
    
    // MARK: - State Persistence
    private func loadPersistedStateForCurrentQuestion() {
        if let savedAnswer = answeredOptions[currentIndex] {
            selectedAnswer = savedAnswer
            answerSubmitted = true
            isAnswerDisabled = true
        } else {
            selectedAnswer = nil
            answerSubmitted = false
            isAnswerDisabled = false
        }
        
        if let savedTime = remainingTimes[currentIndex] {
            timeRemaining = savedTime
        } else if let question = currentQuestion,
                  question.questiionType == "text" || question.questiionType == "htmlText" {
            timeRemaining = Int(estimatedDuration(for: question))
        } else {
            timeRemaining = 60
        }
        
        if bookmarkStates[currentIndex] == true {
            bookmarkedQuestions.insert(currentIndex)
        } else {
            bookmarkedQuestions.remove(currentIndex)
        }
        
        isTimerActive = true
        
        // Resume timer if unanswered and there is remaining time.
        if !answerSubmitted && timeRemaining > 0 {
            resumeTimerForCurrentQuestion()
        } else {
            pauseTimerForCurrentQuestion()
        }
    }
    
    /// Uses the Core ML model to predict the duration for text/HTML questions.
    func estimatedDuration(for question: Quiz) -> TimeInterval {
        guard let text = question.question,
              question.questiionType == "text" || question.questiionType == "htmlText" else {
            return 60
        }
        
        let words = text.split { $0.isWhitespace }
        let wordCount = Double(words.count)
        let averageWordLength = words.map { Double($0.count) }.reduce(0, +) / max(wordCount, 1)
        
        do {
            let prediction = try durationEstimator.prediction(wordCount: wordCount, averageWordLength: averageWordLength)
            return prediction.duration
        } catch {
            print("Model prediction failed: \(error)")
            return 60
        }
    }
    
    func loadCurrentState() {
        loadPersistedStateForCurrentQuestion()
    }
    
    // MARK: - Timer Control
    func pauseTimerForCurrentQuestion() {
        isTimerPaused = true
        remainingTimes[currentIndex] = timeRemaining
    }
    
    func resumeTimerForCurrentQuestion() {
        // Resume only if there is remaining time and the question hasn't been answered.
        if timeRemaining > 0 && !answerSubmitted {
            isTimerPaused = false
        }
    }
    
    func updateTimer() {
        guard !isTimerPaused, timeRemaining > 0 else { return }
        timeRemaining -= 1
        if timeRemaining == 0 {
            answerSubmitted = true
            pauseTimerForCurrentQuestion()
        }
    }
    
    // MARK: - Answer Selection & Navigation
    func selectAnswer(_ index: Int) {
        guard !isAnswerDisabled else { return }
        selectedAnswer = index
        answerSubmitted = true
        isAnswerDisabled = true
        answeredOptions[currentIndex] = index
        remainingTimes[currentIndex] = timeRemaining
    }
    
    func nextQuestion() {
        scrollResetID = UUID()
        pauseTimerForCurrentQuestion()
        
        if currentIndex < quizList.count - 1 {
            currentIndex += 1
            if currentIndex > maxIndexReached {
                maxIndexReached = currentIndex
            }
            loadPersistedStateForCurrentQuestion()
            resumeTimerForCurrentQuestion() // Resume timer after loading new question
        }
    }
    
    func previousQuestion() {
        scrollResetID = UUID()
        pauseTimerForCurrentQuestion()
        
        if currentIndex > 0 {
            currentIndex -= 1
            loadPersistedStateForCurrentQuestion()
            resumeTimerForCurrentQuestion() // Resume timer after loading new question
        }
    }
    
    func resetQuiz() {
        currentIndex = 0
        maxIndexReached = 0
        selectedAnswer = nil
        timeRemaining = 60
        isAnswerDisabled = false
        answerSubmitted = false
        isTimerActive = true
        bookmarkedQuestions.removeAll()
        answeredOptions = [:]
        remainingTimes = [:]
        bookmarkStates = [:]
        for index in 0..<quizList.count {
            remainingTimes[index] = 60
            bookmarkStates[index] = false
        }
    }
    
    // MARK: - Bookmark Logic
    @MainActor func toggleBookmark() {
        guard let question = currentQuestion else { return }
        question.hasBookmarked.toggle()
        coreDataStack.saveContext()
        
        let isBookmarked = bookmarkStates[currentIndex] ?? false
        let newState = !isBookmarked
        bookmarkStates[currentIndex] = newState
        if newState {
            bookmarkedQuestions.insert(currentIndex)
        } else {
            bookmarkedQuestions.remove(currentIndex)
        }
    }
    
    @MainActor
    func fetchBookmarkedQuestions() async {
        let predicate = NSPredicate(format: "hasBookmarked == %@", NSNumber(value: true))
        self.quizList = await coreDataStack.fetchEntities(ofType: Quiz.self, predicate: predicate)
    }
}
