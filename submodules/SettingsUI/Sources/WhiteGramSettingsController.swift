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
            return "Настройка Чатов"
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
            case .chatFolders:
                pushController?(whiteGramChatFoldersSettingsController(context: context))
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
