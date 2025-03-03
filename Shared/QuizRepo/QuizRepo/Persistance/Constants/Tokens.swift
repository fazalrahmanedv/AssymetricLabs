import Foundation
import UIKit
public class Tokens {
    public static let shared = Tokens()
    private let userDefaults = UserDefaults.standard
    private let accessTokenKey = "AccessToken"
    private let mattermostTokenKey = "MattermostToken"
    private let mattermostIDKey = "MattermostID"
    private let firstNameKey = "firstName"
    private let lastNameKey = "lastName"
    private let profileImageKey = "profileImage"
    private let mattermostTeamIDKey = "MattermostTeamID"
    private let mattermostSocketURL = "mattermostSocketURL"
    private let currentChannelKey = "currentChannel"
    private let chatEditDeleteDuration = "chat_edit_delete_duration"
    private let fileShareToken = "fileShareToken"
    private let driveToken = "driveToken"
    private let driveTokenGeneratedOn = "driveTokenGeneratedOn"
    private let calendarToken = "calendarToken"
    private let calendarTokenGeneratedOn = "calendarTokenGeneratedOn"
    private let userID = "userID"
    public var accessToken: String? {
        get {
            return userDefaults.string(forKey: accessTokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: accessTokenKey)
        }
    }
    public var fileshareToken: String? {
        get {
            return userDefaults.string(forKey: fileShareToken)
        }
        set {
            userDefaults.set(newValue, forKey: fileShareToken)
        }
    }
    public var drivetoken: String? {
        get {
            return userDefaults.string(forKey: driveToken)
        }
        set {
            userDefaults.set(newValue, forKey: driveToken)
        }
    }
    public var calendartoken: String? {
        get {
            return userDefaults.string(forKey: calendarToken)
        }
        set {
            userDefaults.set(newValue, forKey: calendarToken)
        }
    }
    public var drivetokenGeneratedOn: String? {
        get {
            return userDefaults.string(forKey: driveTokenGeneratedOn)
        }
        set {
            userDefaults.set(newValue, forKey: driveTokenGeneratedOn)
        }
    }
    public var calendartokenGeneratedOn: String? {
        get {
            return userDefaults.string(forKey: calendarTokenGeneratedOn)
        }
        set {
            userDefaults.set(newValue, forKey: calendarTokenGeneratedOn)
        }
    }
    public var mattermostToken: String? {
        get {
            return userDefaults.string(forKey: mattermostTokenKey)
        }
        set {
            userDefaults.set(newValue, forKey: mattermostTokenKey)
        }
    }
    public var mattermostID: String? {
        get {
            return userDefaults.string(forKey: mattermostIDKey)
        }
        set {
            userDefaults.set(newValue, forKey: mattermostIDKey)
        }
    }
    public var mattermostTeamID: String? {
        get {
            return userDefaults.string(forKey: mattermostTeamIDKey)
        }
        set {
            userDefaults.set(newValue, forKey: mattermostTeamIDKey)
        }
    }
    public var mattermostSocketurl: String? {
        get {
            return userDefaults.string(forKey: mattermostSocketURL)
        }
        set {
            userDefaults.set(newValue, forKey: mattermostSocketURL)
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
    public var profileImage: Data? {
        get {
            return userDefaults.data(forKey: profileImageKey)
        }
        set {
            userDefaults.set(newValue, forKey: profileImageKey)
        }
    }
    public var currentChannel: String? {
        get {
            return userDefaults.string(forKey: currentChannelKey)
        }
        set {
            userDefaults.set(newValue, forKey: currentChannelKey)
        }
    }
    public var editDeleteDuration: String? {
        get {
            return userDefaults.string(forKey: chatEditDeleteDuration)
        }
        set {
            userDefaults.set(newValue, forKey: chatEditDeleteDuration)
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
