import Foundation
public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}
public enum ApiEndPoint {
    case quizList(method: HttpMethod)
    case countriesList(method: HttpMethod)
}
extension ApiEndPoint {
    var baseUrl: String {
        switch self {
        case .quizList:
            return "https://6789df4ddd587da7ac27e4c2.mockapi.io/"
        case .countriesList:
            return "https://restcountries.com/"
        }
    }
    var path: String {
        switch self {
        case .quizList:
            return "api/v1/mcq/content"
        case .countriesList:
            return "v3.1/all"
        }
    }
    var url: URL {
        return URL(string: self.baseUrl + self.path)!
    }
    var httpMethod: HttpMethod {
        switch self {
        case .quizList(let method),
             .countriesList(let method):
            return method
        }
    }
    var headers: [String: String]? {
        switch self {
        case .quizList, .countriesList:
            return [
                "Accept": "application/json",
                "Authorization": "Bearer \(Tokens.shared.accessToken ?? "")"
            ]
        }
    }
}
