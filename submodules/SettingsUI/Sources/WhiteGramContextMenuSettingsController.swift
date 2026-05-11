import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private enum WhiteGramContextMenusSettingsSection: Int32 {
    case chatList
    case privateAndGroups
    case channels
    case settings
}

private enum WhiteGramContextMenuOption: String, CaseIterable {
    // Список чатов
    case chatListFolder
    case chatListMark
    case chatListArchive
    case chatListPin
    case chatListMute
    case chatListDelete
    
    // Внутри чатов — личные сообщения или группы
    case privateReply
    case privateCopy
    case privateForward
    case privateHideName
    case privateDelete
    case privateAddToFavorites
    case privatePin
    case privateRemove
    case privateSelect
    
    // Внутри чатов — каналы
    case channelReply
    case channelCopy
    case channelCopyLink
    case channelForward
    case channelHideName
    case channelReport
    case channelDelete
    case channelSaveToFavorites
    case channelPin
    case channelRemove
    case channelSelect
    
    // Настройки
    case settingsSavedMessages
    case settingsRecentCalls
    case settingsDevices
    case settingsChatFolders
    case settingsPremium
    case settingsStars
    case settingsBusiness
    case settingsGifts
    case settingsHelp
    case settingsFAQ
    case settingsFeatures
    
    var title: String {
        switch self {
        case .chatListFolder:
            return "Добавить или убрать в/из папки"
        case .chatListMark:
            return "Пометить"
        case .chatListArchive:
            return "Архивировать"
        case .chatListPin:
            return "Закрепить"
        case .chatListMute:
            return "Выкл. или вкл. уведомления"
        case .chatListDelete:
            return "Удалить"
            
        case .privateReply:
            return "Ответить"
        case .privateCopy:
            return "Скопировать"
        case .privateForward:
            return "Переслать"
        case .privateHideName:
            return "Спрятать имя"
        case .privateDelete:
            return "Удалить"
        case .privateAddToFavorites:
            return "Добавить в избранное"
        case .privatePin:
            return "Закрепить"
        case .privateRemove:
            return "Удалить"
        case .privateSelect:
            return "Выбрать"
            
        case .channelReply:
            return "Ответить"
        case .channelCopy:
            return "Скопировать"
        case .channelCopyLink:
            return "Скопировать ссылку"
        case .channelForward:
            return "Переслать"
        case .channelHideName:
            return "Спрятать имя"
        case .channelReport:
            return "Пожаловаться"
        case .channelDelete:
            return "Удалить"
        case .channelSaveToFavorites:
            return "Сохранить в избранное"
        case .channelPin:
            return "Закрепить"
        case .channelRemove:
            return "Удалить"
        case .channelSelect:
            return "Выбрать"
            
        case .settingsSavedMessages:
            return "Избранное"
        case .settingsRecentCalls:
            return "Недавние звонки"
        case .settingsDevices:
            return "Устройства"
        case .settingsChatFolders:
            return "Папки с чатами"
        case .settingsPremium:
            return "Telegram Premium"
        case .settingsStars:
            return "Мои звезды"
        case .settingsBusiness:
            return "Telegram для бизнеса"
        case .settingsGifts:
            return "Telegram Gifts"
        case .settingsHelp:
            return "Помощь"
        case .settingsFAQ:
            return "Вопросы о Telegram"
        case .settingsFeatures:
            return "Возможности Telegram"
        }
    }
    
    var section: WhiteGramContextMenusSettingsSection {
        switch self {
        case .chatListFolder, .chatListMark, .chatListArchive, .chatListPin, .chatListMute, .chatListDelete:
            return .chatList
            
        case .privateReply, .privateCopy, .privateForward, .privateHideName, .privateDelete, .privateAddToFavorites, .privatePin, .privateRemove, .privateSelect:
            return .privateAndGroups
            
        case .channelReply, .channelCopy, .channelCopyLink, .channelForward, .channelHideName, .channelReport, .channelDelete, .channelSaveToFavorites, .channelPin, .channelRemove, .channelSelect:
            return .channels
            
        case .settingsSavedMessages, .settingsRecentCalls, .settingsDevices, .settingsChatFolders, .settingsPremium, .settingsStars, .settingsBusiness, .settingsGifts, .settingsHelp, .settingsFAQ, .settingsFeatures:
            return .settings
        }
    }
    
    var storageKey: String {
        return "whitegram.contextMenus.\(self.rawValue)"
    }
}

private struct WhiteGramContextMenusSettingsState: Equatable {
    var values: [WhiteGramContextMenuOption: Bool]
    
    init() {
        var values: [WhiteGramContextMenuOption: Bool] = [:]
        
        for option in WhiteGramContextMenuOption.allCases {
            if UserDefaults.standard.object(forKey: option.storageKey) == nil {
                values[option] = true
            } else {
                values[option] = UserDefaults.standard.bool(forKey: option.storageKey)
            }
        }
        
        self.values = values
    }
    
    func value(_ option: WhiteGramContextMenuOption) -> Bool {
        return self.values[option] ?? true
    }
    
    mutating func setValue(_ value: Bool, for option: WhiteGramContextMenuOption) {
        self.values[option] = value
        UserDefaults.standard.set(value, forKey: option.storageKey)
    }
}

private final class WhiteGramContextMenusSettingsArguments {
    let updateOption: (WhiteGramContextMenuOption, Bool) -> Void
    
    init(updateOption: @escaping (WhiteGramContextMenuOption, Bool) -> Void) {
        self.updateOption = updateOption
    }
}

private enum WhiteGramContextMenusSettingsEntry: ItemListNodeEntry {
    case header(WhiteGramContextMenusSettingsSection, String)
    case option(WhiteGramContextMenuOption, Bool)
    
    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section.rawValue
        case let .option(option, _):
            return option.section.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section.rawValue * 1000
        case let .option(option, _):
            let index = WhiteGramContextMenuOption.allCases.firstIndex(of: option) ?? 0
            return option.section.rawValue * 1000 + Int32(index + 1)
        }
    }
    
    static func ==(lhs: WhiteGramContextMenusSettingsEntry, rhs: WhiteGramContextMenusSettingsEntry) -> Bool {
        switch lhs {
        case let .header(lhsSection, lhsText):
            if case let .header(rhsSection, rhsText) = rhs {
                return lhsSection == rhsSection && lhsText == rhsText
            }
            return false
            
        case let .option(lhsOption, lhsValue):
            if case let .option(rhsOption, rhsValue) = rhs {
                return lhsOption == rhsOption && lhsValue == rhsValue
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramContextMenusSettingsEntry, rhs: WhiteGramContextMenusSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramContextMenusSettingsArguments
        
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
            
        case let .option(option, value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: option.title,
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateOption(option, value)
                }
            )
        }
    }
}

private func whiteGramContextMenusSettingsEntries(state: WhiteGramContextMenusSettingsState) -> [WhiteGramContextMenusSettingsEntry] {
    var entries: [WhiteGramContextMenusSettingsEntry] = []
    
    entries.append(.header(.chatList, "Список чатов"))
    entries.append(.option(.chatListFolder, state.value(.chatListFolder)))
    entries.append(.option(.chatListMark, state.value(.chatListMark)))
    entries.append(.option(.chatListArchive, state.value(.chatListArchive)))
    entries.append(.option(.chatListPin, state.value(.chatListPin)))
    entries.append(.option(.chatListMute, state.value(.chatListMute)))
    entries.append(.option(.chatListDelete, state.value(.chatListDelete)))
    
    entries.append(.header(.privateAndGroups, "Внутри чатов — личные сообщения или группы"))
    entries.append(.option(.privateReply, state.value(.privateReply)))
    entries.append(.option(.privateCopy, state.value(.privateCopy)))
    entries.append(.option(.privateForward, state.value(.privateForward)))
    entries.append(.option(.privateHideName, state.value(.privateHideName)))
    entries.append(.option(.privateDelete, state.value(.privateDelete)))
    entries.append(.option(.privateAddToFavorites, state.value(.privateAddToFavorites)))
    entries.append(.option(.privatePin, state.value(.privatePin)))
    entries.append(.option(.privateRemove, state.value(.privateRemove)))
    entries.append(.option(.privateSelect, state.value(.privateSelect)))
    
    entries.append(.header(.channels, "Внутри чатов — каналы"))
    entries.append(.option(.channelReply, state.value(.channelReply)))
    entries.append(.option(.channelCopy, state.value(.channelCopy)))
    entries.append(.option(.channelCopyLink, state.value(.channelCopyLink)))
    entries.append(.option(.channelForward, state.value(.channelForward)))
    entries.append(.option(.channelHideName, state.value(.channelHideName)))
    entries.append(.option(.channelReport, state.value(.channelReport)))
    entries.append(.option(.channelDelete, state.value(.channelDelete)))
    entries.append(.option(.channelSaveToFavorites, state.value(.channelSaveToFavorites)))
    entries.append(.option(.channelPin, state.value(.channelPin)))
    entries.append(.option(.channelRemove, state.value(.channelRemove)))
    entries.append(.option(.channelSelect, state.value(.channelSelect)))
    
    entries.append(.header(.settings, "Настройки"))
    entries.append(.option(.settingsSavedMessages, state.value(.settingsSavedMessages)))
    entries.append(.option(.settingsRecentCalls, state.value(.settingsRecentCalls)))
    entries.append(.option(.settingsDevices, state.value(.settingsDevices)))
    entries.append(.option(.settingsChatFolders, state.value(.settingsChatFolders)))
    entries.append(.option(.settingsPremium, state.value(.settingsPremium)))
    entries.append(.option(.settingsStars, state.value(.settingsStars)))
    entries.append(.option(.settingsBusiness, state.value(.settingsBusiness)))
    entries.append(.option(.settingsGifts, state.value(.settingsGifts)))
    entries.append(.option(.settingsHelp, state.value(.settingsHelp)))
    entries.append(.option(.settingsFAQ, state.value(.settingsFAQ)))
    entries.append(.option(.settingsFeatures, state.value(.settingsFeatures)))
    
    return entries
}

public func whiteGramContextMenusSettingsController(context: AccountContext) -> ViewController {
    var currentState = WhiteGramContextMenusSettingsState()
    let statePromise = ValuePromise<WhiteGramContextMenusSettingsState>(currentState, ignoreRepeated: true)
    
    let arguments = WhiteGramContextMenusSettingsArguments(
        updateOption: { option, value in
            currentState.setValue(value, for: option)
            statePromise.set(currentState)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, WhiteGramContextMenusSettingsArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, WhiteGramContextMenusSettingsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Контекстные меню"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramContextMenusSettingsEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}