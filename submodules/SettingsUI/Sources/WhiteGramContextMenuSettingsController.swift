import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private func whiteGramString(_ strings: PresentationStrings, ru: String, en: String) -> String {
    return strings.baseLanguageCode.lowercased().hasPrefix("ru") ? ru : en
}

private enum WhiteGramContextMenusSettingsSection: Int32 {
    case chatList
    case privateAndGroups
    case channels
    case settings
}

private extension WhiteGramContextMenuOption {
    func title(strings: PresentationStrings) -> String {
        switch self {
        case .chatListFolder:
            return whiteGramString(strings, ru: "Добавить или убрать в/из папки", en: "Add or Remove from Folder")
        case .chatListMark:
            return whiteGramString(strings, ru: "Пометить", en: "Mark")
        case .chatListArchive:
            return whiteGramString(strings, ru: "Архивировать", en: "Archive")
        case .chatListPin:
            return whiteGramString(strings, ru: "Закрепить", en: "Pin")
        case .chatListMute:
            return whiteGramString(strings, ru: "Выкл. или вкл. уведомления", en: "Mute or Unmute")
        case .chatListDelete:
            return whiteGramString(strings, ru: "Удалить", en: "Delete")
            
        case .privateReply:
            return whiteGramString(strings, ru: "Ответить", en: "Reply")
        case .privateCopy:
            return whiteGramString(strings, ru: "Скопировать", en: "Copy")
        case .privateEdit:
            return whiteGramString(strings, ru: "Редактировать", en: "Edit")
        case .privateForward:
            return whiteGramString(strings, ru: "Переслать", en: "Forward")
        case .privateHideName:
            return whiteGramString(strings, ru: "Спрятать имя", en: "Hide Name")
        case .privateDelete:
            return whiteGramString(strings, ru: "Удалить", en: "Delete")
        case .privateAddToFavorites:
            return whiteGramString(strings, ru: "Добавить в избранное", en: "Add to Favorites")
        case .privatePin:
            return whiteGramString(strings, ru: "Закрепить", en: "Pin")
        case .privateRemove:
            return whiteGramString(strings, ru: "Удалить", en: "Remove")
        case .privateSelect:
            return whiteGramString(strings, ru: "Выбрать", en: "Select")
            
        case .channelReply:
            return whiteGramString(strings, ru: "Ответить", en: "Reply")
        case .channelCopy:
            return whiteGramString(strings, ru: "Скопировать", en: "Copy")
        case .channelCopyLink:
            return whiteGramString(strings, ru: "Скопировать ссылку", en: "Copy Link")
        case .channelEdit:
            return whiteGramString(strings, ru: "Редактировать", en: "Edit")
        case .channelForward:
            return whiteGramString(strings, ru: "Переслать", en: "Forward")
        case .channelHideName:
            return whiteGramString(strings, ru: "Спрятать имя", en: "Hide Name")
        case .channelReport:
            return whiteGramString(strings, ru: "Пожаловаться", en: "Report")
        case .channelDelete:
            return whiteGramString(strings, ru: "Удалить", en: "Delete")
        case .channelSaveToFavorites:
            return whiteGramString(strings, ru: "Сохранить в избранное", en: "Save to Favorites")
        case .channelPin:
            return whiteGramString(strings, ru: "Закрепить", en: "Pin")
        case .channelRemove:
            return whiteGramString(strings, ru: "Удалить", en: "Remove")
        case .channelSelect:
            return whiteGramString(strings, ru: "Выбрать", en: "Select")
            
        case .settingsSavedMessages:
            return whiteGramString(strings, ru: "Избранное", en: "Saved Messages")
        case .settingsRecentCalls:
            return whiteGramString(strings, ru: "Недавние звонки", en: "Recent Calls")
        case .settingsDevices:
            return whiteGramString(strings, ru: "Устройства", en: "Devices")
        case .settingsChatFolders:
            return whiteGramString(strings, ru: "Папки с чатами", en: "Chat Folders")
        case .settingsPremium:
            return "Telegram Premium"
        case .settingsStars:
            return whiteGramString(strings, ru: "Мои звезды", en: "My Stars")
        case .settingsBusiness:
            return whiteGramString(strings, ru: "Telegram для бизнеса", en: "Telegram Business")
        case .settingsGifts:
            return "Telegram Gifts"
        case .settingsHelp:
            return whiteGramString(strings, ru: "Помощь", en: "Help")
        case .settingsFAQ:
            return whiteGramString(strings, ru: "Вопросы о Telegram", en: "Telegram FAQ")
        case .settingsFeatures:
            return whiteGramString(strings, ru: "Возможности Telegram", en: "Telegram Features")
        }
    }
    
    var section: WhiteGramContextMenusSettingsSection {
        switch self {
        case .chatListFolder, .chatListMark, .chatListArchive, .chatListPin, .chatListMute, .chatListDelete:
            return .chatList
            
        case .privateReply, .privateCopy, .privateEdit, .privateForward, .privateHideName, .privateDelete, .privateAddToFavorites, .privatePin, .privateRemove, .privateSelect:
            return .privateAndGroups
            
        case .channelReply, .channelCopy, .channelCopyLink, .channelEdit, .channelForward, .channelHideName, .channelReport, .channelDelete, .channelSaveToFavorites, .channelPin, .channelRemove, .channelSelect:
            return .channels
            
        case .settingsSavedMessages, .settingsRecentCalls, .settingsDevices, .settingsChatFolders, .settingsPremium, .settingsStars, .settingsBusiness, .settingsGifts, .settingsHelp, .settingsFAQ, .settingsFeatures:
            return .settings
        }
    }
    
}

private typealias WhiteGramContextMenusSettingsState = WhiteGramContextMenuSettings

private extension WhiteGramContextMenuSettings {
    func value(_ option: WhiteGramContextMenuOption) -> Bool {
        return self.isEnabled(option)
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
                title: option.title(strings: presentationData.strings),
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

private func whiteGramContextMenusSettingsEntries(strings: PresentationStrings, state: WhiteGramContextMenusSettingsState) -> [WhiteGramContextMenusSettingsEntry] {
    var entries: [WhiteGramContextMenusSettingsEntry] = []
    
    entries.append(.header(.chatList, whiteGramString(strings, ru: "Список чатов", en: "Chat List")))
    entries.append(.option(.chatListFolder, state.value(.chatListFolder)))
    entries.append(.option(.chatListMark, state.value(.chatListMark)))
    entries.append(.option(.chatListArchive, state.value(.chatListArchive)))
    entries.append(.option(.chatListPin, state.value(.chatListPin)))
    entries.append(.option(.chatListMute, state.value(.chatListMute)))
    entries.append(.option(.chatListDelete, state.value(.chatListDelete)))
    
    entries.append(.header(.privateAndGroups, whiteGramString(strings, ru: "Внутри чатов - личные сообщения или группы", en: "Inside Chats - Private Messages or Groups")))
    entries.append(.option(.privateReply, state.value(.privateReply)))
    entries.append(.option(.privateCopy, state.value(.privateCopy)))
    entries.append(.option(.privateEdit, state.value(.privateEdit)))
    entries.append(.option(.privateForward, state.value(.privateForward)))
    entries.append(.option(.privateHideName, state.value(.privateHideName)))
    entries.append(.option(.privateDelete, state.value(.privateDelete)))
    entries.append(.option(.privateAddToFavorites, state.value(.privateAddToFavorites)))
    entries.append(.option(.privatePin, state.value(.privatePin)))
    entries.append(.option(.privateRemove, state.value(.privateRemove)))
    entries.append(.option(.privateSelect, state.value(.privateSelect)))
    
    entries.append(.header(.channels, whiteGramString(strings, ru: "Внутри чатов - каналы", en: "Inside Chats - Channels")))
    entries.append(.option(.channelReply, state.value(.channelReply)))
    entries.append(.option(.channelCopy, state.value(.channelCopy)))
    entries.append(.option(.channelCopyLink, state.value(.channelCopyLink)))
    entries.append(.option(.channelEdit, state.value(.channelEdit)))
    entries.append(.option(.channelForward, state.value(.channelForward)))
    entries.append(.option(.channelHideName, state.value(.channelHideName)))
    entries.append(.option(.channelReport, state.value(.channelReport)))
    entries.append(.option(.channelDelete, state.value(.channelDelete)))
    entries.append(.option(.channelSaveToFavorites, state.value(.channelSaveToFavorites)))
    entries.append(.option(.channelPin, state.value(.channelPin)))
    entries.append(.option(.channelRemove, state.value(.channelRemove)))
    entries.append(.option(.channelSelect, state.value(.channelSelect)))
    
    entries.append(.header(.settings, whiteGramString(strings, ru: "Настройки", en: "Settings")))
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
            title: .text(whiteGramString(presentationData.strings, ru: "Контекстные меню", en: "Context Menus")),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramContextMenusSettingsEntries(strings: presentationData.strings, state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}
