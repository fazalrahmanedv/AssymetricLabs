import Alamofire
import JDStatusBarNotification
public class ApiManager {
    public let sessionManager: SessionManager
    private let reachability: ReachabilityManager
    private static var sharedInstance: ApiManager = {
        let manager = ApiManager(sessionManager: SessionManager(), reachability: ReachabilityManager.shared)
        return manager
    }()
    private let queue = DispatchQueue(label: "com.quizapp.service", qos: .background, attributes: .concurrent)
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var dataTask: DataRequest?
    private var activityIndicator: UIActivityIndicatorView?
    public static func shared() -> ApiManager {
        return sharedInstance
    }
    private init(sessionManager: SessionManager, reachability: ReachabilityManager) {
        self.sessionManager = sessionManager
        self.reachability = reachability
    }
    public func request<T: Decodable>(endPoint: ApiEndPoint, params: Parameters? = nil, requestBody: Bool = false, isChat: Bool = false, bodyParams: [String]? = nil, handler: @escaping ((T?, Error?) -> Void)) {
        guard self.isNetworkReachable() else {
            self.showToast(title: "No Internet", message: "Check your connection and try again.")
            return
        }
        startBackgroundTask()
        let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        var request = URLRequest(url: endPoint.url, cachePolicy: cachePolicy, timeoutInterval: 30)
        request.httpShouldHandleCookies = false
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = endPoint.httpMethod.rawValue
        request.allHTTPHeaderFields = endPoint.headers
        do {
            request = try endPoint.encoding.encode(request, with: params)
        } catch {
            self.endBackgroundTask()
            handler(nil, error)
        }
        if requestBody {
            do {
                if let params = bodyParams {
                    let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
                    request.httpBody = jsonData
                }
            } catch {
                self.endBackgroundTask()
                handler(nil, error)
            }
        }
        dataTask = self.sessionManager.request(request).responseData(queue: queue) { (response) in
            self.endBackgroundTask()
            if let error = response.error {
                if (error as NSError).code == NSURLErrorTimedOut {
                    self.showToast(title: "error", message: "The request timed out.")
                    print("Request timed out.")
                } else {
                    print("Error: \(error.localizedDescription)")
                }
                handler(nil, error)
                return
            }
            guard let httpResponse = response.response else {
                let error = NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP Response"])
                handler(nil, error)
                return
            }
            switch httpResponse.statusCode {
            case 200...299:
                if let data = response.data {
                    do {
                        let result = try JSONDecoder().decode(T.self, from: data)
                        handler(result, nil)
                    } catch {
                        print("ParseError: \(error.localizedDescription)")
                        let error = NSError(domain: "ParseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                        handler(nil, error)
                    }
                } else {
                    _ = NSError(domain: "ResponseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                    handler(nil, nil)
                }
            case 400...499:
                if httpResponse.statusCode == 401 {
                    let notification = NSNotification.Name(rawValue: "api401")
                    NotificationCenter.default.post(name: notification, object: nil)
                } else if httpResponse.statusCode == 400 {
                    if endPoint.path.contains("/login/generate-otp") || (endPoint.path.contains("login/verify-otp") && endPoint.httpMethod == .post) {
                        if let data = response.data {
                            do {
                                let result = try JSONDecoder().decode(T.self, from: data)
                                let error = NSError(domain: "ValidationError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid data"])
                                handler(result, error)
                            } catch {
                                print("ParseError: \(error.localizedDescription)")
                                let error = NSError(domain: "ParseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
                                handler(nil, error)
                            }
                        } else {
                            let error = NSError(domain: "ResponseError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                            handler(nil, nil)
                        }
                        return
                    }
                } else if httpResponse.statusCode == 403 {
                    if isChat {
                        if endPoint.path.contains("/members/me") || (endPoint.path.hasSuffix("/members")  || (endPoint.path.hasSuffix("/stats")) && endPoint.httpMethod == .get) {
                        } else {
                            self.showToast(title: "error", message: "Something went wrong", duration: 3.0)
                        }
                    } else {
                        let notification = NSNotification.Name(rawValue: "api403")
                        NotificationCenter.default.post(name: notification, object: nil)
                    }
                }
                let error = NSError(domain: "ClientError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Client Error"])
                handler(nil, error)
            case 500...599:
                let error = NSError(domain: "ServerError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server Error"])
                handler(nil, error)
            default:
                let error = NSError(domain: "UnknownError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown Error"])
                handler(nil, error)
            }
        }
    }
}
extension ApiManager {
    public func isNetworkReachable() -> Bool {
        return reachability.isNetworkReachable()
    }
    fileprivate func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    fileprivate func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    public func showToast(title: String?, message: String?, duration: TimeInterval = 2.0) {
        DispatchQueue.main.async {
            let styleName: () = NotificationPresenter.shared.updateDefaultStyle {  style in
                style.leftViewStyle.spacing = 5.0
                style.backgroundStyle.backgroundType = .pill
                style.backgroundStyle.backgroundColor = .secondarySystemGroupedBackground
                style.textStyle.textColor = .label
                style.subtitleStyle.textColor = .secondaryLabel
                style.animationType = .move
                style.leftViewStyle.alignment = .centerWithText
                return style
            }
            NotificationPresenter.shared.present(title?.capitalized ?? "", subtitle: message?.capitalized ?? "", includedStyle: .defaultStyle)
            NotificationPresenter.shared.dismiss(after: duration) { presenter in }
        }
    }
}
