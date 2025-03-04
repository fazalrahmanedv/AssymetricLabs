import Foundation
public struct QuizResponse: Codable {
    public let uuidIdentifier: String?
    public let questionType: QuestionTypeEnum?
    public let question: String?
    public let option1, option2, option3, option4: String?
    public let correctOption, sort: Int?
    public let solution: [Solution]?
    public init(
        uuidIdentifier: String?,
        questionType: QuestionTypeEnum?,
        question: String?,
        option1: String?,
        option2: String?,
        option3: String?,
        option4: String?,
        correctOption: Int?,
        sort: Int?,
        solution: [Solution]?
    ) {
        self.uuidIdentifier = uuidIdentifier
        self.questionType = questionType
        self.question = question
        self.option1 = option1
        self.option2 = option2
        self.option3 = option3
        self.option4 = option4
        self.correctOption = correctOption
        self.sort = sort
        self.solution = solution
    }
}
public enum QuestionTypeEnum: String, Codable {
    case htmlText = "htmlText"
    case image = "image"
    case text = "text"
}
public struct Solution: Codable {
    public let contentType: QuestionTypeEnum?
    public let contentData: String?

    public init(contentType: QuestionTypeEnum?, contentData: String?) {
        self.contentType = contentType
        self.contentData = contentData
    }
}
