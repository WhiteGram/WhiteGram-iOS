import Foundation

public struct WhiteGramTabSettings: Codable, Equatable {
    private static let storageKey = "WhiteGramTabSettings.v1"
    
    public static let updatedNotification = Notification.Name("WhiteGramTabSettingsUpdated")
    
    public var compactPanel: Bool
    public var hideContactsTab: Bool
    public var hideCallsTab: Bool
    public var hideTabTitles: Bool
    public var hideSearchButton: Bool
    public var widePanel: Bool
    
    public static let defaultSettings = WhiteGramTabSettings(
        compactPanel: false,
        hideContactsTab: false,
        hideCallsTab: false,
        hideTabTitles: false,
        hideSearchButton: false,
        widePanel: false
    )
    
    public static var current: WhiteGramTabSettings {
        if let data = UserDefaults.standard.data(forKey: self.storageKey), let value = try? JSONDecoder().decode(WhiteGramTabSettings.self, from: data) {
            return value
        }
        return .defaultSettings
    }
    
    public func save(notify: Bool = true) {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
            if notify {
                NotificationCenter.default.post(name: Self.updatedNotification, object: nil)
            }
        }
    }
}
