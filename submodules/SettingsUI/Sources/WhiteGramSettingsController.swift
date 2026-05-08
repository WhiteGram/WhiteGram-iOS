import Foundation
import UIKit
import Darwin
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private final class WhiteGramSettingsArguments {
    let openCategory: (WhiteGramSettingsCategory) -> Void
    
    init(openCategory: @escaping (WhiteGramSettingsCategory) -> Void) {
        self.openCategory = openCategory
    }
}

private enum WhiteGramSettingsSection: Int32 {
    case main
}

private enum WhiteGramSettingsCategory: Int32, CaseIterable {
    case tabs
    case chatSettings
    case chatFolders
    case stories
    case media
    case other
    
    var title: String {
        switch self {
        case .tabs:
            return "Вкладки"
        case .chatSettings:
            return "Настройки чатов"
        case .chatFolders:
            return "Папки с чатами"
        case .stories:
            return "Истории"
        case .media:
            return "Медиа"
        case .other:
            return "Другие"
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .tabs:
            return PresentationResourcesSettings.appearance
        case .chatSettings:
            return PresentationResourcesSettings.chatAppearance
        case .chatFolders:
            return PresentationResourcesSettings.chatFolders
        case .stories:
            return PresentationResourcesSettings.stories
        case .media:
            return PresentationResourcesSettings.photosBlue
        case .other:
            return PresentationResourcesSettings.settings
        }
    }
}

private enum WhiteGramSettingsEntry: ItemListNodeEntry {
    case category(WhiteGramSettingsCategory)
    
    var section: ItemListSectionId {
        return WhiteGramSettingsSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .category(category):
            return category.rawValue
        }
    }
    
    static func ==(lhs: WhiteGramSettingsEntry, rhs: WhiteGramSettingsEntry) -> Bool {
        switch lhs {
        case let .category(lhsCategory):
            if case let .category(rhsCategory) = rhs {
                return lhsCategory == rhsCategory
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramSettingsEntry, rhs: WhiteGramSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramSettingsArguments
        switch self {
        case let .category(category):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: category.icon,
                title: category.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openCategory(category)
                }
            )
        }
    }
}

private func whiteGramSettingsEntries() -> [WhiteGramSettingsEntry] {
    return WhiteGramSettingsCategory.allCases.map(WhiteGramSettingsEntry.category)
}

public func whiteGramSettingsController(context: AccountContext) -> ViewController {
    var pushController: ((ViewController) -> Void)?
    
    let arguments = WhiteGramSettingsArguments(
        openCategory: { category in
            switch category {
            case .tabs:
                pushController?(whiteGramTabsSettingsController(context: context))
            case .chatSettings:
                pushController?(whiteGramChatSettingsController(context: context))
            case .chatFolders:
                pushController?(whiteGramChatFoldersSettingsController(context: context))
            case .stories:
                pushController?(whiteGramStorySettingsController(context: context))
            default:
                break
            }
        }
    )
    
    let signal = context.sharedContext.presentationData
    |> deliverOnMainQueue
    |> map { presentationData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("WhiteGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramSettingsEntries(),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    pushController = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private final class WhiteGramStorySettingsArguments {
    let update: ((WhiteGramStorySettings) -> WhiteGramStorySettings) -> Void

    init(update: @escaping ((WhiteGramStorySettings) -> WhiteGramStorySettings) -> Void) {
        self.update = update
    }
}

private enum WhiteGramStorySettingsSection: Int32 {
    case options
}

private enum WhiteGramStorySettingsEntry: ItemListNodeEntry {
    case disableStories(WhiteGramStorySettings)
    case hideStories(WhiteGramStorySettings)
    case disableStoryRecording(WhiteGramStorySettings)
    case disableStoryRecordingSwipe(WhiteGramStorySettings)
    case askBeforeViewingStories(WhiteGramStorySettings)

    var section: ItemListSectionId {
        return WhiteGramStorySettingsSection.options.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .disableStories:
            return 0
        case .hideStories:
            return 1
        case .disableStoryRecording:
            return 2
        case .disableStoryRecordingSwipe:
            return 3
        case .askBeforeViewingStories:
            return 4
        }
    }

    static func ==(lhs: WhiteGramStorySettingsEntry, rhs: WhiteGramStorySettingsEntry) -> Bool {
        switch lhs {
        case let .disableStories(lhsSettings):
            if case let .disableStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideStories(lhsSettings):
            if case let .hideStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .disableStoryRecording(lhsSettings):
            if case let .disableStoryRecording(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .disableStoryRecordingSwipe(lhsSettings):
            if case let .disableStoryRecordingSwipe(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .askBeforeViewingStories(lhsSettings):
            if case let .askBeforeViewingStories(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }

    static func <(lhs: WhiteGramStorySettingsEntry, rhs: WhiteGramStorySettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramStorySettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case let .disableStories(settings):
            return switchItem(title: "Отключить истории полностью", text: "Скрывает истории и отключает просмотр, создание и запись.", value: settings.disableStories, enabled: true, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStories = value
                    if value {
                        current.hideStories = true
                        current.disableStoryRecording = true
                        current.disableStoryRecordingSwipe = true
                    }
                    return current
                }
            })
        case let .hideStories(settings):
            return switchItem(title: "Скрыть истории", text: "Скрывает истории сверху в списке чатов, но не отключает запись.", value: settings.hideStories, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.hideStories = value
                    return current
                }
            })
        case let .disableStoryRecording(settings):
            return switchItem(title: "Отключить запись истории", text: "Отключает только создание историй, просмотр остается доступен.", value: settings.disableStoryRecording, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStoryRecording = value
                    return current
                }
            })
        case let .disableStoryRecordingSwipe(settings):
            return switchItem(title: "Отключить свайп для записи", text: "Отключает свайп вправо в списке чатов для записи истории.", value: settings.disableStoryRecordingSwipe, enabled: !settings.disableStories && !settings.disableStoryRecording, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableStoryRecordingSwipe = value
                    return current
                }
            })
        case let .askBeforeViewingStories(settings):
            return switchItem(title: "Спросить перед просмотром", text: "Перед открытием истории показывает предупреждение, что владелец увидит просмотр.", value: settings.askBeforeViewingStories, enabled: !settings.disableStories, update: { value in
                arguments.update { current in
                    var current = current
                    current.askBeforeViewingStories = value
                    return current
                }
            })
        }
    }
}

private func whiteGramStorySettingsEntries(settings: WhiteGramStorySettings) -> [WhiteGramStorySettingsEntry] {
    return [
        .disableStories(settings),
        .hideStories(settings),
        .disableStoryRecording(settings),
        .disableStoryRecordingSwipe(settings),
        .askBeforeViewingStories(settings)
    ]
}

private func whiteGramStorySettingsController(context: AccountContext) -> ViewController {
    let initialSettings = WhiteGramStorySettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)

    let arguments = WhiteGramStorySettingsArguments(update: { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        statePromise.set(updated)
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Истории"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramStorySettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private final class WhiteGramTabsSettingsArguments {
    let update: (((WhiteGramTabSettings) -> WhiteGramTabSettings), Bool) -> Void
    let restart: () -> Void
    
    init(update: @escaping (((WhiteGramTabSettings) -> WhiteGramTabSettings), Bool) -> Void, restart: @escaping () -> Void) {
        self.update = update
        self.restart = restart
    }
}

private enum WhiteGramTabsSettingsSection: Int32 {
    case options
    case restart
}

private enum WhiteGramTabsSettingsEntry: ItemListNodeEntry {
    case compactPanel(WhiteGramTabSettings)
    case hideContacts(WhiteGramTabSettings)
    case hideCalls(WhiteGramTabSettings)
    case hideTitles(WhiteGramTabSettings)
    case hideSearch(WhiteGramTabSettings)
    case widePanel(WhiteGramTabSettings)
    case restartFooter
    
    var section: ItemListSectionId {
        switch self {
        case .compactPanel, .hideContacts, .hideCalls, .hideTitles, .hideSearch, .widePanel:
            return WhiteGramTabsSettingsSection.options.rawValue
        case .restartFooter:
            return WhiteGramTabsSettingsSection.restart.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .compactPanel:
            return 0
        case .hideContacts:
            return 1
        case .hideCalls:
            return 2
        case .hideTitles:
            return 3
        case .hideSearch:
            return 4
        case .widePanel:
            return 5
        case .restartFooter:
            return 6
        }
    }
    
    static func ==(lhs: WhiteGramTabsSettingsEntry, rhs: WhiteGramTabsSettingsEntry) -> Bool {
        switch lhs {
        case let .compactPanel(lhsSettings):
            if case let .compactPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideContacts(lhsSettings):
            if case let .hideContacts(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideCalls(lhsSettings):
            if case let .hideCalls(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideTitles(lhsSettings):
            if case let .hideTitles(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideSearch(lhsSettings):
            if case let .hideSearch(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .widePanel(lhsSettings):
            if case let .widePanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .restartFooter:
            if case .restartFooter = rhs {
                return true
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramTabsSettingsEntry, rhs: WhiteGramTabsSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramTabsSettingsArguments
        
        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }
        
        switch self {
        case let .compactPanel(settings):
            return switchItem(title: "Сократить панель вкладок", text: "Скрывает нижнюю панель и переносит вкладки в компактное меню.", value: settings.compactPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactPanel = value
                    return current
                }, true)
            })
        case let .hideContacts(settings):
            return switchItem(title: "Вкладка контакты", text: "Показывает вкладку контактов в нижней панели.", value: !settings.hideContactsTab, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideContactsTab = !value
                    return current
                }, true)
            })
        case let .hideCalls(settings):
            return switchItem(title: "Вкладка звонки", text: "Показывает вкладку звонков рядом с чатами.", value: !settings.hideCallsTab, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideCallsTab = !value
                    return current
                }, true)
            })
        case let .hideTitles(settings):
            return switchItem(title: "Подписи вкладок", text: "Показывает названия вкладок под иконками.", value: !settings.hideTabTitles, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideTabTitles = !value
                    return current
                }, true)
            })
        case let .hideSearch(settings):
            return switchItem(title: "Кнопка поиска", text: "Показывает отдельную кнопку поиска справа от вкладок.", value: !settings.hideSearchButton, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideSearchButton = !value
                    return current
                }, true)
            })
        case let .widePanel(settings):
            return switchItem(title: "Широкая панель", text: "Растягивает панель по доступной ширине с обычными отступами.", value: settings.widePanel, enabled: !settings.compactPanel, update: { value in
                arguments.update({ current in
                    var current = current
                    current.widePanel = value
                    return current
                }, true)
            })
        case .restartFooter:
            return WhiteGramRestartFooterItem(
                presentationData: presentationData,
                sectionId: self.section,
                action: arguments.restart
            )
        }
    }
}

private final class WhiteGramRestartFooterItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let sectionId: ItemListSectionId
    let action: () -> Void
    
    init(presentationData: ItemListPresentationData, sectionId: ItemListSectionId, action: @escaping () -> Void) {
        self.presentationData = presentationData
        self.sectionId = sectionId
        self.action = action
    }
    
    var selectable: Bool {
        return false
    }
    
    func selected(listView: ListView) {
    }
    
    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = WhiteGramRestartFooterItemNode()
            let (layout, apply) = node.asyncLayout()(self, params)
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in
                        apply(false)
                    })
                })
            }
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? WhiteGramRestartFooterItemNode {
                let makeLayout = nodeValue.asyncLayout()
                async {
                    let (layout, apply) = makeLayout(self, params)
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply(animation.isAnimated)
                        })
                    }
                }
            }
        }
    }
}

private final class WhiteGramRestartFooterItemNode: ListViewItemNode {
    private let backgroundView = UIView()
    private let iconLabel = UILabel()
    private let titleLabel = UILabel()
    private let button = UIButton(type: .system)
    private var action: (() -> Void)?
    
    override init(layerBacked: Bool = false, rotated: Bool = false, seeThrough: Bool = false) {
        super.init(layerBacked: layerBacked, rotated: rotated, seeThrough: seeThrough)
        
        self.backgroundView.backgroundColor = UIColor(white: 0.22, alpha: 0.92)
        self.backgroundView.layer.cornerRadius = 24.0
        self.backgroundView.clipsToBounds = true
        self.view.addSubview(self.backgroundView)
        
        self.iconLabel.text = "i"
        self.iconLabel.textAlignment = .center
        self.iconLabel.font = Font.semibold(24.0)
        self.iconLabel.textColor = .white
        self.iconLabel.backgroundColor = UIColor(white: 1.0, alpha: 0.16)
        self.iconLabel.layer.cornerRadius = 19.0
        self.iconLabel.clipsToBounds = true
        self.backgroundView.addSubview(self.iconLabel)
        
        self.titleLabel.text = "Необходим\nперезапуск"
        self.titleLabel.numberOfLines = 2
        self.titleLabel.font = Font.semibold(17.0)
        self.titleLabel.textColor = .white
        self.backgroundView.addSubview(self.titleLabel)
        
        self.button.setTitle("Перезапустить Сейчас", for: [])
        self.button.titleLabel?.font = Font.semibold(17.0)
        self.button.setTitleColor(UIColor(rgb: 0x35C8FF), for: [])
        self.button.addTarget(self, action: #selector(self.buttonPressed), for: .touchUpInside)
        self.backgroundView.addSubview(self.button)
    }
    
    @objc private func buttonPressed() {
        self.action?()
    }
    
    func asyncLayout() -> (_ item: WhiteGramRestartFooterItem, _ params: ListViewItemLayoutParams) -> (ListViewItemNodeLayout, (Bool) -> Void) {
        return { item, params in
            let contentSize = CGSize(width: params.width, height: 74.0)
            let insets = UIEdgeInsets(top: 8.0, left: 0.0, bottom: 8.0, right: 0.0)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)
            
            return (layout, { [weak self] _ in
                guard let self else {
                    return
                }
                self.action = item.action
                
                let sideInset: CGFloat = 16.0
                let frame = CGRect(x: params.leftInset + sideInset, y: 6.0, width: params.width - params.leftInset - params.rightInset - sideInset * 2.0, height: 62.0)
                self.backgroundView.frame = frame
                self.iconLabel.frame = CGRect(x: 14.0, y: 12.0, width: 38.0, height: 38.0)
                self.titleLabel.frame = CGRect(x: 66.0, y: 10.0, width: 150.0, height: 42.0)
                self.button.frame = CGRect(x: max(210.0, frame.width - 205.0), y: 0.0, width: min(205.0, frame.width - 210.0), height: frame.height)
            })
        }
    }
}

private func whiteGramTabsSettingsEntries(settings: WhiteGramTabSettings) -> [WhiteGramTabsSettingsEntry] {
    return [
        .compactPanel(settings),
        .hideContacts(settings),
        .hideCalls(settings),
        .hideTitles(settings),
        .hideSearch(settings),
        .widePanel(settings)
    ]
}

private func whiteGramTabsSettingsController(context: AccountContext) -> ViewController {
    let settings = WhiteGramTabSettings.current
    let statePromise = ValuePromise(settings, ignoreRepeated: true)
    let stateValue = Atomic(value: settings)
    
    let updateSettings: (((WhiteGramTabSettings) -> WhiteGramTabSettings), Bool) -> Void = { f, notify in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save(notify: notify)
            return updated
        }
        statePromise.set(updated)
    }
    
    let arguments = WhiteGramTabsSettingsArguments(
        update: updateSettings,
        restart: {
            exit(0)
        }
    )
    
    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Вкладки"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramTabsSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}

private final class WhiteGramChatSettingsArguments {
    let update: (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void
    let openVideoMessageCamera: () -> Void
    let openPersonalChatDoubleTapAction: () -> Void
    let openChannelPostDoubleTapAction: () -> Void
    let restart: () -> Void

    init(
        update: @escaping (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void,
        openVideoMessageCamera: @escaping () -> Void,
        openPersonalChatDoubleTapAction: @escaping () -> Void,
        openChannelPostDoubleTapAction: @escaping () -> Void,
        restart: @escaping () -> Void
    ) {
        self.update = update
        self.openVideoMessageCamera = openVideoMessageCamera
        self.openPersonalChatDoubleTapAction = openPersonalChatDoubleTapAction
        self.openChannelPostDoubleTapAction = openChannelPostDoubleTapAction
        self.restart = restart
    }
}

private enum WhiteGramChatSettingsSection: Int32 {
    case chatList
    case general
    case stickerSize
    case stickerOptions
    case messages
    case channels
    case restart
}

private enum WhiteGramChatSettingsEntry: ItemListNodeEntry {
    case generalHeader
    case compactPinnedMessagesPanel(WhiteGramChatSettings)
    case stickerSizeHeader
    case stickerSize(WhiteGramChatSettings)
    case animatePremiumStickers(WhiteGramChatSettings)
    case animateEmojiStickers(WhiteGramChatSettings)
    case messagesHeader
    case showSecondsInMessageTimestamp(WhiteGramChatSettings)
    case hideMessageTimestamp(WhiteGramChatSettings)
    case videoMessageCamera(WhiteGramChatSettings)
    case confirmVoiceRecording(WhiteGramChatSettings)
    case voiceMessageButton(WhiteGramChatSettings)
    case swipeToReply(WhiteGramChatSettings)
    case personalChatDoubleTapAction(WhiteGramChatSettings)
    case personalChatDoubleTapInfo
    case channelsHeader
    case channelBottomPanel(WhiteGramChatSettings)
    case wideChannelPosts(WhiteGramChatSettings)
    case channelSwipeToNext(WhiteGramChatSettings)
    case channelPostReactions(WhiteGramChatSettings)
    case channelPostDoubleTapAction(WhiteGramChatSettings)
    case channelPostDoubleTapInfo
    case chatListHeader
    case compactChatList(WhiteGramChatSettings)
    case chatSwipeOptions(WhiteGramChatSettings)
    case chatSwipeDelete(WhiteGramChatSettings)
    case restartFooter

    var section: ItemListSectionId {
        switch self {
        case .generalHeader, .compactPinnedMessagesPanel:
            return WhiteGramChatSettingsSection.general.rawValue
        case .stickerSizeHeader, .stickerSize:
            return WhiteGramChatSettingsSection.stickerSize.rawValue
        case .animatePremiumStickers, .animateEmojiStickers:
            return WhiteGramChatSettingsSection.stickerOptions.rawValue
        case .messagesHeader, .showSecondsInMessageTimestamp, .hideMessageTimestamp, .videoMessageCamera, .confirmVoiceRecording, .voiceMessageButton, .swipeToReply, .personalChatDoubleTapAction, .personalChatDoubleTapInfo:
            return WhiteGramChatSettingsSection.messages.rawValue
        case .channelsHeader, .channelBottomPanel, .wideChannelPosts, .channelSwipeToNext, .channelPostReactions, .channelPostDoubleTapAction, .channelPostDoubleTapInfo:
            return WhiteGramChatSettingsSection.channels.rawValue
        case .chatListHeader, .compactChatList, .chatSwipeOptions, .chatSwipeDelete:
            return WhiteGramChatSettingsSection.chatList.rawValue
        case .restartFooter:
            return WhiteGramChatSettingsSection.restart.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .chatListHeader:
            return 0
        case .compactChatList:
            return 1
        case .chatSwipeOptions:
            return 2
        case .chatSwipeDelete:
            return 3
        case .generalHeader:
            return 4
        case .compactPinnedMessagesPanel:
            return 5
        case .stickerSizeHeader:
            return 6
        case .stickerSize:
            return 7
        case .animatePremiumStickers:
            return 8
        case .animateEmojiStickers:
            return 9
        case .messagesHeader:
            return 10
        case .showSecondsInMessageTimestamp:
            return 11
        case .hideMessageTimestamp:
            return 12
        case .videoMessageCamera:
            return 13
        case .confirmVoiceRecording:
            return 14
        case .voiceMessageButton:
            return 15
        case .swipeToReply:
            return 16
        case .personalChatDoubleTapAction:
            return 17
        case .personalChatDoubleTapInfo:
            return 18
        case .channelsHeader:
            return 19
        case .channelBottomPanel:
            return 20
        case .wideChannelPosts:
            return 21
        case .channelSwipeToNext:
            return 22
        case .channelPostReactions:
            return 23
        case .channelPostDoubleTapAction:
            return 24
        case .channelPostDoubleTapInfo:
            return 25
        case .restartFooter:
            return 26
        }
    }

    static func ==(lhs: WhiteGramChatSettingsEntry, rhs: WhiteGramChatSettingsEntry) -> Bool {
        switch lhs {
        case .generalHeader:
            if case .generalHeader = rhs {
                return true
            }
            return false
        case let .compactPinnedMessagesPanel(lhsSettings):
            if case let .compactPinnedMessagesPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .stickerSizeHeader:
            if case .stickerSizeHeader = rhs {
                return true
            }
            return false
        case let .stickerSize(lhsSettings):
            if case let .stickerSize(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .animatePremiumStickers(lhsSettings):
            if case let .animatePremiumStickers(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .animateEmojiStickers(lhsSettings):
            if case let .animateEmojiStickers(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .messagesHeader:
            if case .messagesHeader = rhs {
                return true
            }
            return false
        case let .showSecondsInMessageTimestamp(lhsSettings):
            if case let .showSecondsInMessageTimestamp(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .hideMessageTimestamp(lhsSettings):
            if case let .hideMessageTimestamp(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .videoMessageCamera(lhsSettings):
            if case let .videoMessageCamera(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .confirmVoiceRecording(lhsSettings):
            if case let .confirmVoiceRecording(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .voiceMessageButton(lhsSettings):
            if case let .voiceMessageButton(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .swipeToReply(lhsSettings):
            if case let .swipeToReply(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .personalChatDoubleTapAction(lhsSettings):
            if case let .personalChatDoubleTapAction(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .personalChatDoubleTapInfo:
            if case .personalChatDoubleTapInfo = rhs {
                return true
            }
            return false
        case .channelsHeader:
            if case .channelsHeader = rhs {
                return true
            }
            return false
        case let .channelBottomPanel(lhsSettings):
            if case let .channelBottomPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .wideChannelPosts(lhsSettings):
            if case let .wideChannelPosts(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelSwipeToNext(lhsSettings):
            if case let .channelSwipeToNext(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelPostReactions(lhsSettings):
            if case let .channelPostReactions(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .channelPostDoubleTapAction(lhsSettings):
            if case let .channelPostDoubleTapAction(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .channelPostDoubleTapInfo:
            if case .channelPostDoubleTapInfo = rhs {
                return true
            }
            return false
        case .chatListHeader:
            if case .chatListHeader = rhs {
                return true
            }
            return false
        case let .compactChatList(lhsSettings):
            if case let .compactChatList(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .chatSwipeOptions(lhsSettings):
            if case let .chatSwipeOptions(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .chatSwipeDelete(lhsSettings):
            if case let .chatSwipeDelete(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case .restartFooter:
            if case .restartFooter = rhs {
                return true
            }
            return false
        }
    }

    static func <(lhs: WhiteGramChatSettingsEntry, rhs: WhiteGramChatSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramChatSettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case .generalHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Закрепленные", sectionId: self.section)
        case let .compactPinnedMessagesPanel(settings):
            return switchItem(title: "Сократить закрепленные", text: "Сокращает закрепленные сообщения в небольшую клавишу.", value: settings.compactPinnedMessagesPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactPinnedMessagesPanel = value
                    return current
                }, true)
            })
        case .stickerSizeHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Размеры одиночных стикеров", sectionId: self.section)
        case let .stickerSize(settings):
            return WhiteGramStickerSizeSliderItem(
                presentationData: presentationData,
                value: settings.stickerSizePercent,
                showTime: settings.showStickerTime,
                sectionId: self.section,
                updatedSize: { value in
                    arguments.update({ current in
                        var current = current
                        current.stickerSizePercent = value
                        return current
                    }, true)
                },
                updatedShowTime: { value in
                    arguments.update({ current in
                        var current = current
                        current.showStickerTime = value
                        return current
                    }, true)
                }
            )
        case let .animatePremiumStickers(settings):
            return switchItem(title: "Анимация премиум стикеров", text: "Включает анимацию премиум стикеров в чате.", value: settings.animatePremiumStickers, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.animatePremiumStickers = value
                    return current
                }, true)
            })
        case let .animateEmojiStickers(settings):
            return switchItem(title: "Анимация эмоджи стикеров", text: "Включает анимацию обычных эмоджи-стикеров.", value: settings.animateEmojiStickers, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.animateEmojiStickers = value
                    return current
                }, true)
            })
        case .messagesHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Сообщения", sectionId: self.section)
        case let .showSecondsInMessageTimestamp(settings):
            return switchItem(title: "Секунды ко времени", text: "Показывает секунды рядом со временем сообщения.", value: settings.showSecondsInMessageTimestamp, enabled: !settings.hideMessageTimestamp, update: { value in
                arguments.update({ current in
                    var current = current
                    current.showSecondsInMessageTimestamp = value
                    return current
                }, true)
            })
        case let .hideMessageTimestamp(settings):
            return switchItem(title: "Отключить время", text: "Скрывает время у сообщений.", value: settings.hideMessageTimestamp, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.hideMessageTimestamp = value
                    if value {
                        current.showSecondsInMessageTimestamp = false
                    }
                    return current
                }, true)
            })
        case let .videoMessageCamera(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Камера видеосообщения",
                label: settings.videoMessageCamera.title,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openVideoMessageCamera
            )
        case let .confirmVoiceRecording(settings):
            return switchItem(title: "Подтверждать запись голосового", text: "Показывает предупреждение перед началом записи голосового.", value: settings.confirmVoiceRecording, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.confirmVoiceRecording = value
                    return current
                }, true)
            })
        case let .voiceMessageButton(settings):
            return switchItem(title: "Клавиша голосового сообщения", text: "Показывает кнопку записи голосового сообщения.", value: settings.voiceMessageButton, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.voiceMessageButton = value
                    return current
                }, true)
            })
        case let .swipeToReply(settings):
            return switchItem(title: "Свайп для ответа на сообщение", text: "Включает ответ свайпом по сообщению.", value: settings.swipeToReply, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.swipeToReply = value
                    return current
                }, true)
            })
        case let .personalChatDoubleTapAction(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Двойной тап в личных чатах",
                label: settings.personalChatDoubleTapAction.title,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openPersonalChatDoubleTapAction
            )
        case .personalChatDoubleTapInfo:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("Выбирает действие, которое выполняется при двойном тапе по сообщению в личных чатах."),
                sectionId: self.section
            )
        case .channelsHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Каналы", sectionId: self.section)
        case let .channelBottomPanel(settings):
            return switchItem(title: "Нижняя панель", text: "Показывает нижнюю панель в каналах: подписаться, отправить подарок и другие действия.", value: settings.channelBottomPanel, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelBottomPanel = value
                    return current
                }, true)
            })
        case let .wideChannelPosts(settings):
            return switchItem(title: "Широкие посты", text: "Расширяет посты каналов до ширины экрана с учетом системных отступов.", value: settings.wideChannelPosts, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.wideChannelPosts = value
                    return current
                }, true)
            })
        case let .channelSwipeToNext(settings):
            return switchItem(title: "Свайп между каналами", text: "Открывает следующий непрочитанный канал свайпом вверх в конце текущего.", value: settings.channelSwipeToNext, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelSwipeToNext = value
                    return current
                }, true)
            })
        case let .channelPostReactions(settings):
            return switchItem(title: "Реакции на постах", text: "Показывает реакции под постами каналов. Ставить реакции можно в любом случае.", value: settings.channelPostReactions, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.channelPostReactions = value
                    return current
                }, true)
            })
        case let .channelPostDoubleTapAction(settings):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Двойной тап по посту",
                label: settings.channelPostDoubleTapAction.title,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: arguments.openChannelPostDoubleTapAction
            )
        case .channelPostDoubleTapInfo:
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain("Выбирает действие, которое выполняется при двойном тапе по посту в канале."),
                sectionId: self.section
            )
        case .chatListHeader:
            return ItemListSectionHeaderItem(presentationData: presentationData, text: "Список чатов", sectionId: self.section)
        case let .compactChatList(settings):
            return switchItem(title: "Компактный список чатов", text: "Уменьшает строки списка и показывает превью в одну строку.", value: settings.compactChatList, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.compactChatList = value
                    return current
                }, false)
            })
        case let .chatSwipeOptions(settings):
            return switchItem(title: "Свайп для опций чатов", text: "Показывает инструменты при свайпе по превью чата.", value: settings.chatSwipeOptions, enabled: true, update: { value in
                arguments.update({ current in
                    var current = current
                    current.chatSwipeOptions = value
                    if !value {
                        current.chatSwipeDelete = false
                    }
                    return current
                }, true)
            })
        case let .chatSwipeDelete(settings):
            return switchItem(title: "Свайп для удаления", text: "Показывает удаление чата среди действий свайпа.", value: settings.chatSwipeDelete, enabled: settings.chatSwipeOptions, update: { value in
                arguments.update({ current in
                    var current = current
                    current.chatSwipeDelete = value
                    return current
                }, true)
            })
        case .restartFooter:
            return WhiteGramRestartFooterItem(
                presentationData: presentationData,
                sectionId: self.section,
                action: arguments.restart
            )
        }
    }
}

private func whiteGramChatSettingsEntries(settings: WhiteGramChatSettings, initialSettings: WhiteGramChatSettings) -> [WhiteGramChatSettingsEntry] {
    var entries: [WhiteGramChatSettingsEntry] = [
        .chatListHeader,
        .compactChatList(settings),
        .chatSwipeOptions(settings),
        .chatSwipeDelete(settings),
        .generalHeader,
        .compactPinnedMessagesPanel(settings),
        .stickerSizeHeader,
        .stickerSize(settings),
        .animatePremiumStickers(settings),
        .animateEmojiStickers(settings),
        .messagesHeader,
        .showSecondsInMessageTimestamp(settings),
        .hideMessageTimestamp(settings),
        .videoMessageCamera(settings),
        .confirmVoiceRecording(settings),
        .voiceMessageButton(settings),
        .swipeToReply(settings),
        .personalChatDoubleTapAction(settings),
        .personalChatDoubleTapInfo,
        .channelsHeader,
        .channelBottomPanel(settings),
        .wideChannelPosts(settings),
        .channelSwipeToNext(settings),
        .channelPostReactions(settings),
        .channelPostDoubleTapAction(settings),
        .channelPostDoubleTapInfo
    ]

    if settings.compactChatList != initialSettings.compactChatList {
        entries.append(.restartFooter)
    }

    return entries
}

private func whiteGramChatSettingsController(context: AccountContext) -> ViewController {
    let _ = WhiteGramChatSettings.effectiveCompactSettings
    let initialSettings = WhiteGramChatSettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)
    var pushController: ((ViewController) -> Void)?

    let updateSettings: (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void = { f, notify in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save(notify: notify)
            return updated
        }
        statePromise.set(updated)
    }

    let arguments = WhiteGramChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {
            pushController?(whiteGramVideoMessageCameraSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        openPersonalChatDoubleTapAction: {
            pushController?(whiteGramPersonalChatDoubleTapSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        openChannelPostDoubleTapAction: {
            pushController?(whiteGramChannelPostDoubleTapSettingsController(context: context, statePromise: statePromise, updateSettings: updateSettings))
        },
        restart: {
            exit(0)
        }
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Настройки чатов"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramChatSettingsEntries(settings: settings, initialSettings: initialSettings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushController = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

private final class WhiteGramStickerSizeSliderItem: ListViewItem, ItemListItem {
    let presentationData: ItemListPresentationData
    let value: Int32
    let showTime: Bool
    let sectionId: ItemListSectionId
    let updatedSize: (Int32) -> Void
    let updatedShowTime: (Bool) -> Void

    init(presentationData: ItemListPresentationData, value: Int32, showTime: Bool, sectionId: ItemListSectionId, updatedSize: @escaping (Int32) -> Void, updatedShowTime: @escaping (Bool) -> Void) {
        self.presentationData = presentationData
        self.value = value
        self.showTime = showTime
        self.sectionId = sectionId
        self.updatedSize = updatedSize
        self.updatedShowTime = updatedShowTime
    }

    var selectable: Bool {
        return false
    }

    func selected(listView: ListView) {
    }

    func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = WhiteGramStickerSizeSliderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params)
            node.contentSize = layout.contentSize
            node.insets = layout.insets
            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in
                        apply(false)
                    })
                })
            }
        }
    }

    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            if let nodeValue = node() as? WhiteGramStickerSizeSliderItemNode {
                let makeLayout = nodeValue.asyncLayout()
                async {
                    let (layout, apply) = makeLayout(self, params)
                    Queue.mainQueue().async {
                        completion(layout, { _ in
                            apply(animation.isAnimated)
                        })
                    }
                }
            }
        }
    }
}

private final class WhiteGramStickerSizeSliderItemNode: ListViewItemNode {
    private let backgroundView = UIView()
    private let minLabel = UILabel()
    private let valueLabel = UILabel()
    private let maxLabel = UILabel()
    private let slider = UISlider()
    private let separatorView = UIView()
    private let showTimeLabel = UILabel()
    private let showTimeSwitch = UISwitch()
    private var updatedSize: ((Int32) -> Void)?
    private var updatedShowTime: ((Bool) -> Void)?
    private var currentValue: Int32 = 100
    private var currentShowTime = true

    override init(layerBacked: Bool = false, rotated: Bool = false, seeThrough: Bool = false) {
        super.init(layerBacked: layerBacked, rotated: rotated, seeThrough: seeThrough)

        self.backgroundView.layer.cornerRadius = 26.0
        self.backgroundView.clipsToBounds = true
        self.view.addSubview(self.backgroundView)

        self.minLabel.text = "0%"
        self.minLabel.font = Font.medium(17.0)
        self.backgroundView.addSubview(self.minLabel)

        self.valueLabel.font = Font.semibold(21.0)
        self.valueLabel.textAlignment = .center
        self.backgroundView.addSubview(self.valueLabel)

        self.maxLabel.text = "100%"
        self.maxLabel.font = Font.medium(17.0)
        self.maxLabel.textAlignment = .right
        self.backgroundView.addSubview(self.maxLabel)

        self.slider.minimumValue = 0.0
        self.slider.maximumValue = 100.0
        self.slider.addTarget(self, action: #selector(self.sliderValueChanged), for: .valueChanged)
        self.backgroundView.addSubview(self.slider)

        self.backgroundView.addSubview(self.separatorView)

        self.showTimeLabel.text = "Показывать время"
        self.showTimeLabel.font = Font.regular(16.0)
        self.backgroundView.addSubview(self.showTimeLabel)

        self.showTimeSwitch.addTarget(self, action: #selector(self.showTimeValueChanged), for: .valueChanged)
        self.backgroundView.addSubview(self.showTimeSwitch)
    }

    @objc private func sliderValueChanged() {
        let roundedValue = Int32((self.slider.value / 5.0).rounded() * 5.0)
        if roundedValue != self.currentValue {
            self.currentValue = roundedValue
            self.valueLabel.text = "\(roundedValue)%"
            self.updatedSize?(roundedValue)
        }
    }

    @objc private func showTimeValueChanged() {
        let value = self.showTimeSwitch.isOn
        if value != self.currentShowTime {
            self.currentShowTime = value
            self.updatedShowTime?(value)
        }
    }

    func asyncLayout() -> (_ item: WhiteGramStickerSizeSliderItem, _ params: ListViewItemLayoutParams) -> (ListViewItemNodeLayout, (Bool) -> Void) {
        return { item, params in
            let contentSize = CGSize(width: params.width, height: 150.0)
            let insets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, { [weak self] _ in
                guard let self else {
                    return
                }

                let theme = item.presentationData.theme
                self.backgroundView.backgroundColor = theme.list.itemBlocksBackgroundColor
                self.minLabel.textColor = theme.list.itemSecondaryTextColor
                self.valueLabel.textColor = theme.list.itemPrimaryTextColor
                self.maxLabel.textColor = theme.list.itemSecondaryTextColor
                self.slider.minimumTrackTintColor = theme.list.itemAccentColor
                self.slider.maximumTrackTintColor = theme.list.itemSecondaryTextColor.withAlphaComponent(0.24)
                self.separatorView.backgroundColor = theme.list.itemBlocksSeparatorColor
                self.showTimeLabel.textColor = theme.list.itemPrimaryTextColor
                self.updatedSize = item.updatedSize
                self.updatedShowTime = item.updatedShowTime
                self.currentValue = min(100, max(0, item.value))
                self.currentShowTime = item.showTime
                self.valueLabel.text = "\(self.currentValue)%"
                self.slider.setValue(Float(self.currentValue), animated: false)
                self.showTimeSwitch.setOn(item.showTime, animated: false)

                let sideInset: CGFloat = 0.0
                let frame = CGRect(x: params.leftInset + sideInset, y: 0.0, width: params.width - params.leftInset - params.rightInset - sideInset * 2.0, height: 150.0)
                self.backgroundView.frame = frame
                self.minLabel.frame = CGRect(x: 18.0, y: 14.0, width: 80.0, height: 32.0)
                self.valueLabel.frame = CGRect(x: 96.0, y: 10.0, width: frame.width - 192.0, height: 38.0)
                self.maxLabel.frame = CGRect(x: frame.width - 98.0, y: 14.0, width: 80.0, height: 32.0)
                self.slider.frame = CGRect(x: 18.0, y: 62.0, width: frame.width - 36.0, height: 32.0)
                self.separatorView.frame = CGRect(x: 0.0, y: 106.0, width: frame.width, height: UIScreenPixel)
                self.showTimeLabel.frame = CGRect(x: 18.0, y: 116.0, width: frame.width - 122.0, height: 34.0)
                self.showTimeSwitch.frame = CGRect(origin: CGPoint(x: frame.width - 69.0, y: 116.0), size: self.showTimeSwitch.bounds.size)
            })
        }
    }
}

private enum WhiteGramVideoMessageCameraSettingsEntry: ItemListNodeEntry {
    case option(WhiteGramChatSettings.VideoMessageCamera, WhiteGramChatSettings.VideoMessageCamera)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: WhiteGramVideoMessageCameraSettingsEntry, rhs: WhiteGramVideoMessageCameraSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: WhiteGramVideoMessageCameraSettingsEntry, rhs: WhiteGramVideoMessageCameraSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title,
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.videoMessageCamera = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension WhiteGramChatSettings.VideoMessageCamera {
    var stableId: Int32 {
        switch self {
        case .front:
            return 0
        case .back:
            return 1
        case .ask:
            return 2
        }
    }
}

private func whiteGramVideoMessageCameraSettingsEntries(settings: WhiteGramChatSettings) -> [WhiteGramVideoMessageCameraSettingsEntry] {
    return WhiteGramChatSettings.VideoMessageCamera.allCases.map { .option($0, settings.videoMessageCamera) }
}

private func whiteGramVideoMessageCameraSettingsController(context: AccountContext, statePromise: ValuePromise<WhiteGramChatSettings>, updateSettings: @escaping (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void) -> ViewController {
    let arguments = WhiteGramChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Камера видеосообщения"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramVideoMessageCameraSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private enum WhiteGramPersonalChatDoubleTapSettingsEntry: ItemListNodeEntry {
    case option(WhiteGramChatSettings.PersonalChatDoubleTapAction, WhiteGramChatSettings.PersonalChatDoubleTapAction)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: WhiteGramPersonalChatDoubleTapSettingsEntry, rhs: WhiteGramPersonalChatDoubleTapSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: WhiteGramPersonalChatDoubleTapSettingsEntry, rhs: WhiteGramPersonalChatDoubleTapSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title,
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.personalChatDoubleTapAction = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension WhiteGramChatSettings.PersonalChatDoubleTapAction {
    var stableId: Int32 {
        switch self {
        case .savedMessages:
            return 0
        case .reaction:
            return 1
        case .edit:
            return 2
        case .forward:
            return 3
        case .reply:
            return 4
        case .pin:
            return 5
        case .select:
            return 6
        case .copy:
            return 7
        case .contextMenu:
            return 8
        }
    }
}

private func whiteGramPersonalChatDoubleTapSettingsEntries(settings: WhiteGramChatSettings) -> [WhiteGramPersonalChatDoubleTapSettingsEntry] {
    return WhiteGramChatSettings.PersonalChatDoubleTapAction.allCases.map { .option($0, settings.personalChatDoubleTapAction) }
}

private func whiteGramPersonalChatDoubleTapSettingsController(context: AccountContext, statePromise: ValuePromise<WhiteGramChatSettings>, updateSettings: @escaping (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void) -> ViewController {
    let arguments = WhiteGramChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Двойной тап"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramPersonalChatDoubleTapSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private enum WhiteGramChannelPostDoubleTapSettingsEntry: ItemListNodeEntry {
    case option(WhiteGramChatSettings.ChannelPostDoubleTapAction, WhiteGramChatSettings.ChannelPostDoubleTapAction)

    var section: ItemListSectionId {
        return 0
    }

    var stableId: Int32 {
        switch self {
        case let .option(option, _):
            return option.stableId
        }
    }

    static func ==(lhs: WhiteGramChannelPostDoubleTapSettingsEntry, rhs: WhiteGramChannelPostDoubleTapSettingsEntry) -> Bool {
        switch lhs {
        case let .option(lhsOption, lhsSelected):
            if case let .option(rhsOption, rhsSelected) = rhs {
                return lhsOption == rhsOption && lhsSelected == rhsSelected
            }
            return false
        }
    }

    static func <(lhs: WhiteGramChannelPostDoubleTapSettingsEntry, rhs: WhiteGramChannelPostDoubleTapSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramChatSettingsArguments

        switch self {
        case let .option(option, selectedOption):
            return ItemListCheckboxItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title,
                style: .left,
                checked: option == selectedOption,
                zeroSeparatorInsets: false,
                sectionId: self.section,
                action: {
                    arguments.update({ current in
                        var current = current
                        current.channelPostDoubleTapAction = option
                        return current
                    }, true)
                }
            )
        }
    }
}

private extension WhiteGramChatSettings.ChannelPostDoubleTapAction {
    var stableId: Int32 {
        switch self {
        case .savedMessages:
            return 0
        case .reaction:
            return 1
        case .forward:
            return 2
        case .reply:
            return 3
        case .select:
            return 4
        case .copy:
            return 5
        case .contextMenu:
            return 6
        }
    }
}

private func whiteGramChannelPostDoubleTapSettingsEntries(settings: WhiteGramChatSettings) -> [WhiteGramChannelPostDoubleTapSettingsEntry] {
    return WhiteGramChatSettings.ChannelPostDoubleTapAction.allCases.map { .option($0, settings.channelPostDoubleTapAction) }
}

private func whiteGramChannelPostDoubleTapSettingsController(context: AccountContext, statePromise: ValuePromise<WhiteGramChatSettings>, updateSettings: @escaping (((WhiteGramChatSettings) -> WhiteGramChatSettings), Bool) -> Void) -> ViewController {
    let arguments = WhiteGramChatSettingsArguments(
        update: updateSettings,
        openVideoMessageCamera: {},
        openPersonalChatDoubleTapAction: {},
        openChannelPostDoubleTapAction: {},
        restart: {}
    )

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Двойной тап"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramChannelPostDoubleTapSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}

private final class WhiteGramChatFoldersSettingsArguments {
    let update: ((WhiteGramChatFolderSettings) -> WhiteGramChatFolderSettings) -> Void

    init(update: @escaping ((WhiteGramChatFolderSettings) -> WhiteGramChatFolderSettings) -> Void) {
        self.update = update
    }
}

private enum WhiteGramChatFoldersSettingsSection: Int32 {
    case options
}

private enum WhiteGramChatFoldersSettingsEntry: ItemListNodeEntry {
    case disableFolders(WhiteGramChatFolderSettings)
    case compactPanel(WhiteGramChatFolderSettings)
    case foldersAtBottom(WhiteGramChatFolderSettings)
    case openLastFolder(WhiteGramChatFolderSettings)

    var section: ItemListSectionId {
        return WhiteGramChatFoldersSettingsSection.options.rawValue
    }

    var stableId: Int32 {
        switch self {
        case .disableFolders:
            return 0
        case .compactPanel:
            return 1
        case .foldersAtBottom:
            return 2
        case .openLastFolder:
            return 3
        }
    }

    static func ==(lhs: WhiteGramChatFoldersSettingsEntry, rhs: WhiteGramChatFoldersSettingsEntry) -> Bool {
        switch lhs {
        case let .disableFolders(lhsSettings):
            if case let .disableFolders(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .compactPanel(lhsSettings):
            if case let .compactPanel(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .foldersAtBottom(lhsSettings):
            if case let .foldersAtBottom(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        case let .openLastFolder(lhsSettings):
            if case let .openLastFolder(rhsSettings) = rhs {
                return lhsSettings == rhsSettings
            }
            return false
        }
    }

    static func <(lhs: WhiteGramChatFoldersSettingsEntry, rhs: WhiteGramChatFoldersSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramChatFoldersSettingsArguments

        func switchItem(title: String, text: String, value: Bool, enabled: Bool, update: @escaping (Bool) -> Void) -> ListViewItem {
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: title,
                text: text,
                value: value,
                enableInteractiveChanges: enabled,
                enabled: enabled,
                sectionId: self.section,
                style: .blocks,
                updated: update
            )
        }

        switch self {
        case let .disableFolders(settings):
            return switchItem(title: "Отключить папки", text: "Полностью скрывает панель папок, даже если папки созданы.", value: settings.disableFolders, enabled: true, update: { value in
                arguments.update { current in
                    var current = current
                    current.disableFolders = value
                    return current
                }
            })
        case let .compactPanel(settings):
            return switchItem(title: "Сократить панель папок", text: "Скрывает панель папок и переносит выбор папок в кнопку наверху.", value: settings.compactPanel, enabled: !settings.disableFolders && !settings.foldersAtBottom, update: { value in
                arguments.update { current in
                    var current = current
                    current.compactPanel = value
                    if value {
                        current.foldersAtBottom = false
                    }
                    return current
                }
            })
        case let .foldersAtBottom(settings):
            return switchItem(title: "Папки снизу", text: "Переносит панель папок в нижнюю часть экрана.", value: settings.foldersAtBottom, enabled: !settings.disableFolders && !settings.compactPanel, update: { value in
                arguments.update { current in
                    var current = current
                    current.foldersAtBottom = value
                    if value {
                        current.compactPanel = false
                    }
                    return current
                }
            })
        case let .openLastFolder(settings):
            return switchItem(title: "Открывать последнюю папку", text: "После перезахода открывает папку, на которой приложение было закрыто.", value: settings.openLastFolder, enabled: !settings.disableFolders, update: { value in
                arguments.update { current in
                    var current = current
                    current.openLastFolder = value
                    return current
                }
            })
        }
    }
}

private func whiteGramChatFoldersSettingsEntries(settings: WhiteGramChatFolderSettings) -> [WhiteGramChatFoldersSettingsEntry] {
    return [
        .disableFolders(settings),
        .compactPanel(settings),
        .foldersAtBottom(settings),
        .openLastFolder(settings)
    ]
}

private func whiteGramChatFoldersSettingsController(context: AccountContext) -> ViewController {
    let initialSettings = WhiteGramChatFolderSettings.current
    let statePromise = ValuePromise(initialSettings, ignoreRepeated: true)
    let stateValue = Atomic(value: initialSettings)

    let arguments = WhiteGramChatFoldersSettingsArguments(update: { f in
        let updated = stateValue.modify { current in
            let updated = f(current)
            updated.save()
            return updated
        }
        statePromise.set(updated)
    })

    let signal = combineLatest(context.sharedContext.presentationData, statePromise.get())
    |> deliverOnMainQueue
    |> map { presentationData, settings -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Папки с чатами"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramChatFoldersSettingsEntries(settings: settings),
            style: .blocks,
            animateChanges: true
        )

        return (controllerState, (listState, arguments))
    }

    return ItemListController(context: context, state: signal)
}
