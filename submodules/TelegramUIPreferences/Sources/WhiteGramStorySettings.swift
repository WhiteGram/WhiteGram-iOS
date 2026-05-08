import Foundation

public struct WhiteGramStorySettings: Codable, Equatable {
    private static let storageKey = "WhiteGramStorySettings.v1"

    public static let updatedNotification = Notification.Name("WhiteGramStorySettingsUpdated")

    public var disableStories: Bool
    public var hideStories: Bool
    public var disableStoryRecording: Bool
    public var disableStoryRecordingSwipe: Bool
    public var askBeforeViewingStories: Bool

    public static let defaultSettings = WhiteGramStorySettings(
        disableStories: false,
        hideStories: false,
        disableStoryRecording: false,
        disableStoryRecordingSwipe: false,
        askBeforeViewingStories: false
    )

    public static var current: WhiteGramStorySettings {
        if let data = UserDefaults.standard.data(forKey: self.storageKey), let value = try? JSONDecoder().decode(WhiteGramStorySettings.self, from: data) {
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
