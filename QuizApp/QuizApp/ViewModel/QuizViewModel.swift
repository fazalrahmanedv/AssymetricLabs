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
    private let durationEstimator = QuestionDurationEstimator()
    @Published var scrollResetID = UUID() // Unique ID to reset scroll position
    // Dictionaries to persist state for each question
    var answeredOptions: [Int: Int] = [:]
    var remainingTimes: [Int: Int] = [:]
    var bookmarkStates: [Int: Bool] = [:]  // Persist bookmark state per question
    let coreDataStack = CoreDataStack.shared
    @Published var quizList: [Quiz] = []
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    init(quizList: [Quiz]) {
            self.quizList = quizList
            // Initialize remaining time and bookmark state for every question.
            for index in 0..<quizList.count {
                let question = quizList[index]
                if  question.questiionType == "text" || question.questiionType == "htmlText" {
                    // Use ML model to predict duration.
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
            // Load persisted selected answer if available.
            if let savedAnswer = answeredOptions[currentIndex] {
                selectedAnswer = savedAnswer
                answerSubmitted = true
                isAnswerDisabled = true
                bookmarkStates[currentIndex] = false
                bookmarkedQuestions.remove(currentIndex)
            } else {
                selectedAnswer = nil
                answerSubmitted = false
                isAnswerDisabled = false
                if bookmarkStates[currentIndex] == true {
                    bookmarkedQuestions.insert(currentIndex)
                } else {
                    bookmarkedQuestions.remove(currentIndex)
                }
            }
            
            // Load persisted remaining time if available, otherwise use ML prediction if applicable.
            if let savedTime = remainingTimes[currentIndex] {
                timeRemaining = savedTime
            } else if let question = currentQuestion,
                      question.questiionType == "text" || question.questiionType == "htmlText" {
                timeRemaining = Int(estimatedDuration(for: question))
            } else {
                timeRemaining = 60
            }
            
            // Resume timer when question becomes visible.
            isTimerActive = true
        }
        
        /// Uses the Core ML model to predict the duration for text/HTML questions.
        func estimatedDuration(for question: Quiz) -> TimeInterval {
            guard let text = question.question,
                  question.questiionType == "text" || question.questiionType == "htmlText" else {
                return 60 // Fallback for non-text questions.
            }
            
            // Extract features: word count and average word length.
            let words = text.split { $0.isWhitespace }
            let wordCount = Double(words.count)
            let averageWordLength = words.map { Double($0.count) }.reduce(0, +) / max(wordCount, 1)
            
            do {
                // Call the ML model's prediction method.
                let prediction = try durationEstimator.prediction(wordCount: wordCount, averageWordLength: averageWordLength)
                return prediction.duration
            } catch {
                print("Model prediction failed: \(error)")
                return 60 // Default duration if prediction fails.
            }
        }
        
    func loadCurrentState() {
        loadPersistedStateForCurrentQuestion()
    }
    
    // MARK: - Timer Control
    
    /// Pauses the timer for the current question and saves the remaining time.
    func pauseTimerForCurrentQuestion() {
        isTimerActive = false
        remainingTimes[currentIndex] = timeRemaining
    }
    
    /// Resumes the timer for the current question.
    func resumeTimerForCurrentQuestion() {
        isTimerActive = true
    }
    
    // MARK: - Answer Selection & Navigation
    
    /// Updates the selected answer without marking it as submitted.
    func selectAnswer(_ index: Int) {
        // Prevent changing an answer if already submitted.
        guard !isAnswerDisabled else { return }
        selectedAnswer = index
        answerSubmitted = true
        isAnswerDisabled = true
        // Persist the selected answer and current time.
        answeredOptions[currentIndex] = index
        remainingTimes[currentIndex] = timeRemaining
    }

    
    /// Advances to the next question and marks the current answer as submitted.
    func nextQuestion() {
        scrollResetID = UUID()
        // Pause timer before navigating away.
        pauseTimerForCurrentQuestion()
        
        // Mark answer as submitted if an answer is selected.
        if selectedAnswer != nil {
            answerSubmitted = true
        }
        
        if currentIndex < quizList.count - 1 {
            // Persist current question state.
            if let selected = selectedAnswer {
                answeredOptions[currentIndex] = selected
            }
            remainingTimes[currentIndex] = timeRemaining
            
            currentIndex += 1
            if currentIndex > maxIndexReached {
                maxIndexReached = currentIndex
            }
            loadPersistedStateForCurrentQuestion()
        }
    }
    
    func previousQuestion() {
        scrollResetID = UUID()
        // Pause timer before navigating away.
        pauseTimerForCurrentQuestion()
        
        if currentIndex > 0 {
            // Persist current state before moving back.
            if let selected = selectedAnswer {
                answeredOptions[currentIndex] = selected
            }
            remainingTimes[currentIndex] = timeRemaining
            
            currentIndex -= 1
            loadPersistedStateForCurrentQuestion()
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
    
    func updateTimer() {
        guard isTimerActive else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            // Timer has timed out.
            isTimerActive = false
            isAnswerDisabled = true
            remainingTimes[currentIndex] = 0
        }
    }
    
    // MARK: - Bookmark Logic
    
    // Toggles bookmark only if the current question is unanswered.
    @MainActor func toggleBookmark() {
        // If the question has been answered, clear bookmark.
        guard let question = currentQuestion else { return }
        question.hasBookmarked.toggle()
        coreDataStack.saveContext()
        if answeredOptions[currentIndex] != nil {
            bookmarkStates[currentIndex] = false
            bookmarkedQuestions.remove(currentIndex)
        } else {
            let isBookmarked = bookmarkStates[currentIndex] ?? false
            let newState = !isBookmarked
            bookmarkStates[currentIndex] = newState
            if newState {
                bookmarkedQuestions.insert(currentIndex)
            } else {
                bookmarkedQuestions.remove(currentIndex)
            }
        }
    }
    @MainActor
    func fetchBookmarkedQuestions() async {
        let predicate = NSPredicate(format: "hasBookmarked == %@", NSNumber(value: true))
        self.quizList = await coreDataStack.fetchEntities(ofType: Quiz.self, predicate: predicate)
    }
}
