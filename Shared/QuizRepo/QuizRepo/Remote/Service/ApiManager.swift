import Foundation
import Combine
import UIKit
public class ApiManager: ObservableObject {
    private let reachability: NetworkManager
    private var cancellables = Set<AnyCancellable>()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let queue = DispatchQueue(label: "com.quizapp.service", qos: .background, attributes: .concurrent)
    public static let shared = ApiManager(reachability: NetworkManager.shared)
    @Published public var isNetworkReachable: Bool = false
    private init(reachability: NetworkManager) {
        self.reachability = reachability
        self.isNetworkReachable = reachability.isNetworkReachable
        // Observe network changes
        self.reachability.$isNetworkReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReachable in
                self?.isNetworkReachable = isReachable
            }
            .store(in: &cancellables)
    }
    // MARK: - Network Request with Async/Await
    public func request<T: Decodable>(endPoint: ApiEndPoint, params: [String: Any]? = nil, requestBody: Bool = false, bodyParams: [String: Any]? = nil) async -> Result<T, ApiError> {
        // Check network availability before proceeding
        guard self.isNetworkReachable else {
            return .failure(.networkUnreachable)
        }
        startBackgroundTask()
        var request = URLRequest(url: endPoint.url)
        request.httpMethod = endPoint.httpMethod.rawValue
        request.allHTTPHeaderFields = endPoint.headers
        if requestBody, let bodyParams = bodyParams {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
            } catch {
                self.endBackgroundTask()
                return .failure(.invalidRequestBody(error.localizedDescription))
            }
        } else if let params = params {
            var urlComponents = URLComponents(url: endPoint.url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = params.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            request.url = urlComponents?.url
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            self.endBackgroundTask()
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let result = try JSONDecoder().decode(T.self, from: data)
                    return .success(result)
                } catch {
                    return .failure(.parseError(error.localizedDescription))
                }
            case 400: return .failure(.badRequest)
            case 401: return .failure(.unauthorized)
            case 403: return .failure(.forbidden)
            case 400...499: return .failure(.clientError)
            case 500...599: return .failure(.serverError)
            default: return .failure(.unknownError)
            }
        } catch {
            self.endBackgroundTask()
            return .failure(.networkError(error.localizedDescription))
        }
    }
    // MARK: - Background Task Handling
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    // MARK: - Custom Error Handling
    public enum ApiError: Error {
        case networkUnreachable
        case invalidResponse
        case parseError(String)
        case unauthorized
        case badRequest
        case forbidden
        case clientError
        case serverError
        case unknownError
        case networkError(String)
        case invalidRequestBody(String)
    }
}
