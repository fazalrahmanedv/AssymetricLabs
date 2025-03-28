import Foundation
import UIKit
public class Tokens {
    public static let shared = Tokens()
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "AccessToken"
    private let firstNameKey = "firstName"
    private let lastNameKey = "lastName"
    private let userID = "userID"
    public var accessToken: String? {
        get {
//           this should be keychain based for now simply using userDefaults for demo purpose
            return userDefaults.string(forKey: accessTokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: accessTokenKey)
        }
    }
    public var firstName: String? {
        get {
            return userDefaults.string(forKey: firstNameKey)
        }
        set {
            userDefaults.set(newValue, forKey: firstNameKey)
        }
    }
    public var lastName: String? {
        get {
            return userDefaults.string(forKey: lastNameKey)
        }
        set {
            userDefaults.set(newValue, forKey: lastNameKey)
        }
    }
    public var userid: Int? {
        get {
            return userDefaults.integer(forKey: userID)
        }
        set {
            userDefaults.set(newValue, forKey: userID)
        }
    }
    private init() {}
    public func clearAllValues() {
        let appDomain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: appDomain)
    }
}
