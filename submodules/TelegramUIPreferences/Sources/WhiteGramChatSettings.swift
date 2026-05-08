import Foundation

public struct WhiteGramChatSettings: Codable, Equatable {
    public enum VideoMessageCamera: String, Codable, Equatable, CaseIterable {
        case front
        case back
        case ask

        public static var allCases: [VideoMessageCamera] {
            return [.front, .back, .ask]
        }

        public var title: String {
            switch self {
            case .front:
                return "Фронтальная"
            case .back:
                return "Задняя"
            case .ask:
                return "Спрашивать"
            }
        }
    }

    public enum PersonalChatDoubleTapAction: String, Codable, Equatable, CaseIterable {
        case savedMessages
        case reaction
        case edit
        case forward
        case reply
        case pin
        case select
        case copy
        case contextMenu

        public static var allCases: [PersonalChatDoubleTapAction] {
            return [.savedMessages, .reaction, .edit, .forward, .reply, .pin, .select, .copy, .contextMenu]
        }

        public var title: String {
            switch self {
            case .savedMessages:
                return "Избранное"
            case .reaction:
                return "Реакция"
            case .edit:
                return "Редактировать сообщение"
            case .forward:
                return "Переслать"
            case .reply:
                return "Ответить"
            case .pin:
                return "Закрепить / открепить"
            case .select:
                return "Выбрать"
            case .copy:
                return "Скопировать"
            case .contextMenu:
                return "Открыть контекстное меню"
            }
        }
    }

    public enum ChannelPostDoubleTapAction: String, Codable, Equatable, CaseIterable {
        case savedMessages
        case reaction
        case forward
        case reply
        case select
        case copy
        case contextMenu

        public static var allCases: [ChannelPostDoubleTapAction] {
            return [.savedMessages, .reaction, .forward, .reply, .select, .copy, .contextMenu]
        }

        public var title: String {
            switch self {
            case .savedMessages:
                return "Добавить в Избранное"
            case .reaction:
                return "Реакция"
            case .forward:
                return "Переслать"
            case .reply:
                return "Ответить"
            case .select:
                return "Выбрать"
            case .copy:
                return "Скопировать"
            case .contextMenu:
                return "Открыть контекстное меню"
            }
        }
    }

    private static let storageKey = "WhiteGramChatSettings.v1"

    public static let updatedNotification = Notification.Name("WhiteGramChatSettingsUpdated")
    public static let effectiveCompactSettings = WhiteGramChatSettings.load()

    public var compactPinnedMessagesPanel: Bool
    public var stickerSizePercent: Int32
    public var showStickerTime: Bool
    public var animatePremiumStickers: Bool
    public var animateEmojiStickers: Bool
    public var showSecondsInMessageTimestamp: Bool
    public var hideMessageTimestamp: Bool
    public var videoMessageCamera: VideoMessageCamera
    public var confirmVoiceRecording: Bool
    public var voiceMessageButton: Bool
    public var swipeToReply: Bool
    public var personalChatDoubleTapAction: PersonalChatDoubleTapAction
    public var channelBottomPanel: Bool
    public var wideChannelPosts: Bool
    public var channelSwipeToNext: Bool
    public var channelPostReactions: Bool
    public var channelPostDoubleTapAction: ChannelPostDoubleTapAction
    public var compactChatList: Bool
    public var chatSwipeOptions: Bool
    public var chatSwipeDelete: Bool

    public static let defaultSettings = WhiteGramChatSettings(
        compactPinnedMessagesPanel: false,
        stickerSizePercent: 100,
        showStickerTime: true,
        animatePremiumStickers: true,
        animateEmojiStickers: true,
        showSecondsInMessageTimestamp: false,
        hideMessageTimestamp: false,
        videoMessageCamera: .ask,
        confirmVoiceRecording: false,
        voiceMessageButton: true,
        swipeToReply: true,
        personalChatDoubleTapAction: .reaction,
        channelBottomPanel: true,
        wideChannelPosts: false,
        channelSwipeToNext: true,
        channelPostReactions: true,
        channelPostDoubleTapAction: .reaction,
        compactChatList: false,
        chatSwipeOptions: true,
        chatSwipeDelete: true
    )

    public init(
        compactPinnedMessagesPanel: Bool,
        stickerSizePercent: Int32,
        showStickerTime: Bool,
        animatePremiumStickers: Bool,
        animateEmojiStickers: Bool,
        showSecondsInMessageTimestamp: Bool,
        hideMessageTimestamp: Bool,
        videoMessageCamera: VideoMessageCamera,
        confirmVoiceRecording: Bool,
        voiceMessageButton: Bool,
        swipeToReply: Bool,
        personalChatDoubleTapAction: PersonalChatDoubleTapAction,
        channelBottomPanel: Bool,
        wideChannelPosts: Bool,
        channelSwipeToNext: Bool,
        channelPostReactions: Bool,
        channelPostDoubleTapAction: ChannelPostDoubleTapAction,
        compactChatList: Bool,
        chatSwipeOptions: Bool,
        chatSwipeDelete: Bool
    ) {
        self.compactPinnedMessagesPanel = compactPinnedMessagesPanel
        self.stickerSizePercent = min(100, max(0, stickerSizePercent))
        self.showStickerTime = showStickerTime
        self.animatePremiumStickers = animatePremiumStickers
        self.animateEmojiStickers = animateEmojiStickers
        self.showSecondsInMessageTimestamp = showSecondsInMessageTimestamp
        self.hideMessageTimestamp = hideMessageTimestamp
        self.videoMessageCamera = videoMessageCamera
        self.confirmVoiceRecording = confirmVoiceRecording
        self.voiceMessageButton = voiceMessageButton
        self.swipeToReply = swipeToReply
        self.personalChatDoubleTapAction = personalChatDoubleTapAction
        self.channelBottomPanel = channelBottomPanel
        self.wideChannelPosts = wideChannelPosts
        self.channelSwipeToNext = channelSwipeToNext
        self.channelPostReactions = channelPostReactions
        self.channelPostDoubleTapAction = channelPostDoubleTapAction
        self.compactChatList = compactChatList
        self.chatSwipeOptions = chatSwipeOptions
        self.chatSwipeDelete = chatSwipeDelete
    }

    private enum CodingKeys: String, CodingKey {
        case compactPinnedMessagesPanel
        case stickerSizePercent
        case showStickerTime
        case animatePremiumStickers
        case animateEmojiStickers
        case showSecondsInMessageTimestamp
        case hideMessageTimestamp
        case videoMessageCamera
        case confirmVoiceRecording
        case voiceMessageButton
        case swipeToReply
        case personalChatDoubleTapAction
        case channelBottomPanel
        case wideChannelPosts
        case channelSwipeToNext
        case channelPostReactions
        case channelPostDoubleTapAction
        case compactChatList
        case chatSwipeOptions
        case chatSwipeDelete
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.compactPinnedMessagesPanel = try container.decodeIfPresent(Bool.self, forKey: .compactPinnedMessagesPanel) ?? Self.defaultSettings.compactPinnedMessagesPanel
        self.stickerSizePercent = min(100, max(0, try container.decodeIfPresent(Int32.self, forKey: .stickerSizePercent) ?? Self.defaultSettings.stickerSizePercent))
        self.showStickerTime = try container.decodeIfPresent(Bool.self, forKey: .showStickerTime) ?? Self.defaultSettings.showStickerTime
        self.animatePremiumStickers = try container.decodeIfPresent(Bool.self, forKey: .animatePremiumStickers) ?? Self.defaultSettings.animatePremiumStickers
        self.animateEmojiStickers = try container.decodeIfPresent(Bool.self, forKey: .animateEmojiStickers) ?? Self.defaultSettings.animateEmojiStickers
        self.showSecondsInMessageTimestamp = try container.decodeIfPresent(Bool.self, forKey: .showSecondsInMessageTimestamp) ?? Self.defaultSettings.showSecondsInMessageTimestamp
        self.hideMessageTimestamp = try container.decodeIfPresent(Bool.self, forKey: .hideMessageTimestamp) ?? Self.defaultSettings.hideMessageTimestamp
        self.videoMessageCamera = try container.decodeIfPresent(VideoMessageCamera.self, forKey: .videoMessageCamera) ?? Self.defaultSettings.videoMessageCamera
        self.confirmVoiceRecording = try container.decodeIfPresent(Bool.self, forKey: .confirmVoiceRecording) ?? Self.defaultSettings.confirmVoiceRecording
        self.voiceMessageButton = try container.decodeIfPresent(Bool.self, forKey: .voiceMessageButton) ?? Self.defaultSettings.voiceMessageButton
        self.swipeToReply = try container.decodeIfPresent(Bool.self, forKey: .swipeToReply) ?? Self.defaultSettings.swipeToReply
        self.personalChatDoubleTapAction = try container.decodeIfPresent(PersonalChatDoubleTapAction.self, forKey: .personalChatDoubleTapAction) ?? Self.defaultSettings.personalChatDoubleTapAction
        self.channelBottomPanel = try container.decodeIfPresent(Bool.self, forKey: .channelBottomPanel) ?? Self.defaultSettings.channelBottomPanel
        self.wideChannelPosts = try container.decodeIfPresent(Bool.self, forKey: .wideChannelPosts) ?? Self.defaultSettings.wideChannelPosts
        self.channelSwipeToNext = try container.decodeIfPresent(Bool.self, forKey: .channelSwipeToNext) ?? Self.defaultSettings.channelSwipeToNext
        self.channelPostReactions = try container.decodeIfPresent(Bool.self, forKey: .channelPostReactions) ?? Self.defaultSettings.channelPostReactions
        self.channelPostDoubleTapAction = try container.decodeIfPresent(ChannelPostDoubleTapAction.self, forKey: .channelPostDoubleTapAction) ?? Self.defaultSettings.channelPostDoubleTapAction
        self.compactChatList = try container.decodeIfPresent(Bool.self, forKey: .compactChatList) ?? Self.defaultSettings.compactChatList
        self.chatSwipeOptions = try container.decodeIfPresent(Bool.self, forKey: .chatSwipeOptions) ?? Self.defaultSettings.chatSwipeOptions
        self.chatSwipeDelete = try container.decodeIfPresent(Bool.self, forKey: .chatSwipeDelete) ?? Self.defaultSettings.chatSwipeDelete
    }

    public static var current: WhiteGramChatSettings {
        return self.load()
    }

    public static var effectiveChatListSettings: WhiteGramChatSettings {
        var settings = self.current
        settings.compactChatList = self.effectiveCompactSettings.compactChatList
        return settings
    }

    private static func load() -> WhiteGramChatSettings {
        if let data = UserDefaults.standard.data(forKey: self.storageKey), let value = try? JSONDecoder().decode(WhiteGramChatSettings.self, from: data) {
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
