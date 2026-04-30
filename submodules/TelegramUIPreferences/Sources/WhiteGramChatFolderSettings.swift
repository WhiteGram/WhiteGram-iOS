import Foundation

public struct WhiteGramChatFolderSettings: Codable, Equatable {
    private static let storageKey = "WhiteGramChatFolderSettings.v1"

    public static let updatedNotification = Notification.Name("WhiteGramChatFolderSettingsUpdated")

    public var disableFolders: Bool
    public var compactPanel: Bool
    public var foldersAtBottom: Bool
    public var openLastFolder: Bool
    public var lastFolderId: Int32?

    public static let defaultSettings = WhiteGramChatFolderSettings(
        disableFolders: false,
        compactPanel: false,
        foldersAtBottom: false,
        openLastFolder: false,
        lastFolderId: nil
    )

    public static var current: WhiteGramChatFolderSettings {
        if let data = UserDefaults.standard.data(forKey: self.storageKey), let value = try? JSONDecoder().decode(WhiteGramChatFolderSettings.self, from: data) {
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
