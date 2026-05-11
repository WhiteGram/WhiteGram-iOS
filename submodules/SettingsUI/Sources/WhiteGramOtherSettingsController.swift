import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private enum WhiteGramOtherTranslationService: String, CaseIterable {
    case telegram
    case gTranslate
    
    var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .gTranslate:
            return "GTranslate"
        }
    }
}

private enum WhiteGramOtherTranscriptionService: String, CaseIterable {
    case telegram
    case apple
    
    var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .apple:
            return "Apple"
        }
    }
}

private struct WhiteGramOtherSettingsState: Equatable {
    var autoTranslate: Bool
    var translationService: WhiteGramOtherTranslationService
    var translationButton: Bool
    
    var voiceTranscription: Bool
    var transcriptionService: WhiteGramOtherTranscriptionService
    
    var forceDeviceMicrophone: Bool
    
    var hideCameraInGallery: Bool
    var hideCameraPreviewInGallery: Bool
    
    init() {
        let defaults = UserDefaults.standard
        
        self.autoTranslate = defaults.object(forKey: "whitegram.other.autoTranslate") as? Bool ?? true
        
        if let rawValue = defaults.string(forKey: "whitegram.other.translationService"), let value = WhiteGramOtherTranslationService(rawValue: rawValue) {
            self.translationService = value
        } else {
            self.translationService = .telegram
        }
        
        self.translationButton = defaults.object(forKey: "whitegram.other.translationButton") as? Bool ?? true
        
        self.voiceTranscription = defaults.object(forKey: "whitegram.other.voiceTranscription") as? Bool ?? true
        
        if let rawValue = defaults.string(forKey: "whitegram.other.transcriptionService"), let value = WhiteGramOtherTranscriptionService(rawValue: rawValue) {
            self.transcriptionService = value
        } else {
            self.transcriptionService = .telegram
        }
        
        self.forceDeviceMicrophone = defaults.object(forKey: "whitegram.other.forceDeviceMicrophone") as? Bool ?? false
        
        self.hideCameraInGallery = defaults.object(forKey: "whitegram.other.hideCameraInGallery") as? Bool ?? false
        self.hideCameraPreviewInGallery = defaults.object(forKey: "whitegram.other.hideCameraPreviewInGallery") as? Bool ?? false
    }
    
    mutating func setAutoTranslate(_ value: Bool) {
        self.autoTranslate = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.autoTranslate")
    }
    
    mutating func setTranslationService(_ value: WhiteGramOtherTranslationService) {
        self.translationService = value
        UserDefaults.standard.set(value.rawValue, forKey: "whitegram.other.translationService")
    }
    
    mutating func setTranslationButton(_ value: Bool) {
        self.translationButton = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.translationButton")
    }
    
    mutating func setVoiceTranscription(_ value: Bool) {
        self.voiceTranscription = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.voiceTranscription")
    }
    
    mutating func setTranscriptionService(_ value: WhiteGramOtherTranscriptionService) {
        self.transcriptionService = value
        UserDefaults.standard.set(value.rawValue, forKey: "whitegram.other.transcriptionService")
    }
    
    mutating func setForceDeviceMicrophone(_ value: Bool) {
        self.forceDeviceMicrophone = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.forceDeviceMicrophone")
    }
    
    mutating func setHideCameraInGallery(_ value: Bool) {
        self.hideCameraInGallery = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.hideCameraInGallery")
    }
    
    mutating func setHideCameraPreviewInGallery(_ value: Bool) {
        self.hideCameraPreviewInGallery = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.hideCameraPreviewInGallery")
    }
}

private enum WhiteGramOtherSettingsSection: Int32 {
    case translation
    case voiceToText
    case voiceAndVideoRecording
    case gallery
}

private enum WhiteGramOtherSettingsEntry: ItemListNodeEntry {
    case header(WhiteGramOtherSettingsSection, String)
    
    case autoTranslate(Bool)
    case translationService(String)
    case translationButton(Bool)
    
    case voiceTranscription(Bool)
    case transcriptionService(String)
    
    case forceDeviceMicrophone(Bool)
    
    case hideCameraInGallery(Bool)
    case hideCameraPreviewInGallery(Bool)
    
    var section: ItemListSectionId {
        switch self {
        case let .header(section, _):
            return section.rawValue
            
        case .autoTranslate, .translationService, .translationButton:
            return WhiteGramOtherSettingsSection.translation.rawValue
            
        case .voiceTranscription, .transcriptionService:
            return WhiteGramOtherSettingsSection.voiceToText.rawValue
            
        case .forceDeviceMicrophone:
            return WhiteGramOtherSettingsSection.voiceAndVideoRecording.rawValue
            
        case .hideCameraInGallery, .hideCameraPreviewInGallery:
            return WhiteGramOtherSettingsSection.gallery.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case let .header(section, _):
            return section.rawValue * 1000
            
        case .autoTranslate:
            return WhiteGramOtherSettingsSection.translation.rawValue * 1000 + 1
        case .translationService:
            return WhiteGramOtherSettingsSection.translation.rawValue * 1000 + 2
        case .translationButton:
            return WhiteGramOtherSettingsSection.translation.rawValue * 1000 + 3
            
        case .voiceTranscription:
            return WhiteGramOtherSettingsSection.voiceToText.rawValue * 1000 + 1
        case .transcriptionService:
            return WhiteGramOtherSettingsSection.voiceToText.rawValue * 1000 + 2
            
        case .forceDeviceMicrophone:
            return WhiteGramOtherSettingsSection.voiceAndVideoRecording.rawValue * 1000 + 1
            
        case .hideCameraInGallery:
            return WhiteGramOtherSettingsSection.gallery.rawValue * 1000 + 1
        case .hideCameraPreviewInGallery:
            return WhiteGramOtherSettingsSection.gallery.rawValue * 1000 + 2
        }
    }
    
    static func ==(lhs: WhiteGramOtherSettingsEntry, rhs: WhiteGramOtherSettingsEntry) -> Bool {
        switch lhs {
        case let .header(lhsSection, lhsText):
            if case let .header(rhsSection, rhsText) = rhs {
                return lhsSection == rhsSection && lhsText == rhsText
            }
            return false
            
        case let .autoTranslate(lhsValue):
            if case let .autoTranslate(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .translationService(lhsValue):
            if case let .translationService(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .translationButton(lhsValue):
            if case let .translationButton(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .voiceTranscription(lhsValue):
            if case let .voiceTranscription(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .transcriptionService(lhsValue):
            if case let .transcriptionService(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .forceDeviceMicrophone(lhsValue):
            if case let .forceDeviceMicrophone(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .hideCameraInGallery(lhsValue):
            if case let .hideCameraInGallery(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
            
        case let .hideCameraPreviewInGallery(lhsValue):
            if case let .hideCameraPreviewInGallery(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramOtherSettingsEntry, rhs: WhiteGramOtherSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramOtherSettingsArguments
        
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(
                presentationData: presentationData,
                text: text,
                sectionId: self.section
            )
            
        case let .autoTranslate(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Включить авто-перевод",
                text: "Включает автоматический перевод постов и сообщений без вашего участия.",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateAutoTranslate(value)
                }
            )
            
        case let .translationService(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: nil,
                title: "Сервис",
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openTranslationService()
                }
            )
            
        case let .translationButton(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Клавиша перевода",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateTranslationButton(value)
                }
            )
            
        case let .voiceTranscription(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Транскрипция",
                text: "Включает или отключает функцию «Голос в текст».",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateVoiceTranscription(value)
                }
            )
            
        case let .transcriptionService(value):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: nil,
                title: "Сервис",
                label: value,
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .arrow,
                action: {
                    arguments.openTranscriptionService()
                }
            )
            
        case let .forceDeviceMicrophone(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Микрофон устройства",
                text: "Запись будет идти с микрофона устройства, даже если подключены другие устройства записи.",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateForceDeviceMicrophone(value)
                }
            )
            
        case let .hideCameraInGallery(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Камера в галерее",
                text: "Отключает блок камеры в галерее.",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateHideCameraInGallery(value)
                }
            )
            
        case let .hideCameraPreviewInGallery(value):
            return ItemListSwitchItem(
                presentationData: presentationData,
                systemStyle: .glass,
                title: "Превью камеры в галерее",
                text: "Превью камеры не показывает картинку с камеры.",
                value: value,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.updateHideCameraPreviewInGallery(value)
                }
            )
        }
    }
}

private final class WhiteGramOtherSettingsArguments {
    let updateAutoTranslate: (Bool) -> Void
    let openTranslationService: () -> Void
    let updateTranslationButton: (Bool) -> Void
    
    let updateVoiceTranscription: (Bool) -> Void
    let openTranscriptionService: () -> Void
    
    let updateForceDeviceMicrophone: (Bool) -> Void
    
    let updateHideCameraInGallery: (Bool) -> Void
    let updateHideCameraPreviewInGallery: (Bool) -> Void
    
    init(
        updateAutoTranslate: @escaping (Bool) -> Void,
        openTranslationService: @escaping () -> Void,
        updateTranslationButton: @escaping (Bool) -> Void,
        updateVoiceTranscription: @escaping (Bool) -> Void,
        openTranscriptionService: @escaping () -> Void,
        updateForceDeviceMicrophone: @escaping (Bool) -> Void,
        updateHideCameraInGallery: @escaping (Bool) -> Void,
        updateHideCameraPreviewInGallery: @escaping (Bool) -> Void
    ) {
        self.updateAutoTranslate = updateAutoTranslate
        self.openTranslationService = openTranslationService
        self.updateTranslationButton = updateTranslationButton
        self.updateVoiceTranscription = updateVoiceTranscription
        self.openTranscriptionService = openTranscriptionService
        self.updateForceDeviceMicrophone = updateForceDeviceMicrophone
        self.updateHideCameraInGallery = updateHideCameraInGallery
        self.updateHideCameraPreviewInGallery = updateHideCameraPreviewInGallery
    }
}

private func whiteGramOtherSettingsEntries(state: WhiteGramOtherSettingsState) -> [WhiteGramOtherSettingsEntry] {
    var entries: [WhiteGramOtherSettingsEntry] = []
    
    entries.append(.header(.translation, "Перевод"))
    entries.append(.autoTranslate(state.autoTranslate))
    entries.append(.translationService(state.translationService.title))
    entries.append(.translationButton(state.translationButton))
    
    entries.append(.header(.voiceToText, "Голос в текст"))
    entries.append(.voiceTranscription(state.voiceTranscription))
    entries.append(.transcriptionService(state.transcriptionService.title))
    
    entries.append(.header(.voiceAndVideoRecording, "Запись голоса и видео"))
    entries.append(.forceDeviceMicrophone(state.forceDeviceMicrophone))
    
    entries.append(.header(.gallery, "Галерея"))
    entries.append(.hideCameraInGallery(state.hideCameraInGallery))
    entries.append(.hideCameraPreviewInGallery(state.hideCameraPreviewInGallery))
    
    return entries
}

private func whiteGramSelectionCheckIcon(color: UIColor) -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    
    guard let context = UIGraphicsGetCurrentContext() else {
        UIGraphicsEndImageContext()
        return nil
    }
    
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(2.2)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    context.move(to: CGPoint(x: 4.5, y: 11.5))
    context.addLine(to: CGPoint(x: 9.0, y: 16.0))
    context.addLine(to: CGPoint(x: 17.5, y: 6.5))
    context.strokePath()
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}

private func whiteGramSelectionEmptyIcon() -> UIImage? {
    let size = CGSize(width: 22.0, height: 22.0)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

public func whiteGramOtherSettingsController(context: AccountContext) -> ViewController {
    var currentState = WhiteGramOtherSettingsState()
    let statePromise = ValuePromise<WhiteGramOtherSettingsState>(currentState, ignoreRepeated: true)
    
    var pushController: ((ViewController) -> Void)?
    
    let arguments = WhiteGramOtherSettingsArguments(
        updateAutoTranslate: { value in
            currentState.setAutoTranslate(value)
            statePromise.set(currentState)
        },
        openTranslationService: {
            pushController?(whiteGramOtherTranslationServiceController(
                context: context,
                statePromise: statePromise,
                updateService: { value in
                    currentState.setTranslationService(value)
                    statePromise.set(currentState)
                }
            ))
        },
        updateTranslationButton: { value in
            currentState.setTranslationButton(value)
            statePromise.set(currentState)
        },
        updateVoiceTranscription: { value in
            currentState.setVoiceTranscription(value)
            statePromise.set(currentState)
        },
        openTranscriptionService: {
            pushController?(whiteGramOtherTranscriptionServiceController(
                context: context,
                statePromise: statePromise,
                updateService: { value in
                    currentState.setTranscriptionService(value)
                    statePromise.set(currentState)
                }
            ))
        },
        updateForceDeviceMicrophone: { value in
            currentState.setForceDeviceMicrophone(value)
            statePromise.set(currentState)
        },
        updateHideCameraInGallery: { value in
            currentState.setHideCameraInGallery(value)
            statePromise.set(currentState)
        },
        updateHideCameraPreviewInGallery: { value in
            currentState.setHideCameraPreviewInGallery(value)
            statePromise.set(currentState)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, WhiteGramOtherSettingsArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, WhiteGramOtherSettingsArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Другие"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramOtherSettingsEntries(state: state),
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

// MARK: - Translation Service Selection

private enum WhiteGramOtherTranslationServiceSelectionSection: Int32 {
    case main
}

private enum WhiteGramOtherTranslationServiceSelectionEntry: ItemListNodeEntry {
    case service(WhiteGramOtherTranslationService, Bool)
    case info(String)
    
    var section: ItemListSectionId {
        return WhiteGramOtherTranslationServiceSelectionSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .service(service, _):
            switch service {
            case .telegram:
                return 0
            case .gTranslate:
                return 1
            }
        case .info:
            return 100
        }
    }
    
    static func ==(lhs: WhiteGramOtherTranslationServiceSelectionEntry, rhs: WhiteGramOtherTranslationServiceSelectionEntry) -> Bool {
        switch lhs {
        case let .service(lhsService, lhsSelected):
            if case let .service(rhsService, rhsSelected) = rhs {
                return lhsService == rhsService && lhsSelected == rhsSelected
            }
            return false
            
        case let .info(lhsText):
            if case let .info(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramOtherTranslationServiceSelectionEntry, rhs: WhiteGramOtherTranslationServiceSelectionEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramOtherTranslationServiceSelectionArguments
        
        switch self {
        case let .service(service, selected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: selected ? whiteGramSelectionCheckIcon(color: presentationData.theme.list.itemAccentColor) : whiteGramSelectionEmptyIcon(),
                title: service.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.selectService(service)
                }
            )
            
        case let .info(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        }
    }
}

private final class WhiteGramOtherTranslationServiceSelectionArguments {
    let selectService: (WhiteGramOtherTranslationService) -> Void
    
    init(selectService: @escaping (WhiteGramOtherTranslationService) -> Void) {
        self.selectService = selectService
    }
}

private func whiteGramOtherTranslationServiceSelectionEntries(state: WhiteGramOtherSettingsState) -> [WhiteGramOtherTranslationServiceSelectionEntry] {
    return [
        .service(.telegram, state.translationService == .telegram),
        .service(.gTranslate, state.translationService == .gTranslate),
        .info("WhiteGram будет использовать GTranslate, если Telegram будет недоступен.")
    ]
}

private func whiteGramOtherTranslationServiceController(
    context: AccountContext,
    statePromise: ValuePromise<WhiteGramOtherSettingsState>,
    updateService: @escaping (WhiteGramOtherTranslationService) -> Void
) -> ViewController {
    let arguments = WhiteGramOtherTranslationServiceSelectionArguments(
        selectService: { service in
            updateService(service)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, WhiteGramOtherTranslationServiceSelectionArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, WhiteGramOtherTranslationServiceSelectionArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Сервис перевода"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramOtherTranslationServiceSelectionEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}

// MARK: - Transcription Service Selection

private enum WhiteGramOtherTranscriptionServiceSelectionSection: Int32 {
    case main
}

private enum WhiteGramOtherTranscriptionServiceSelectionEntry: ItemListNodeEntry {
    case service(WhiteGramOtherTranscriptionService, Bool)
    case info(String)
    
    var section: ItemListSectionId {
        return WhiteGramOtherTranscriptionServiceSelectionSection.main.rawValue
    }
    
    var stableId: Int32 {
        switch self {
        case let .service(service, _):
            switch service {
            case .telegram:
                return 0
            case .apple:
                return 1
            }
        case .info:
            return 100
        }
    }
    
    static func ==(lhs: WhiteGramOtherTranscriptionServiceSelectionEntry, rhs: WhiteGramOtherTranscriptionServiceSelectionEntry) -> Bool {
        switch lhs {
        case let .service(lhsService, lhsSelected):
            if case let .service(rhsService, rhsSelected) = rhs {
                return lhsService == rhsService && lhsSelected == rhsSelected
            }
            return false
            
        case let .info(lhsText):
            if case let .info(rhsText) = rhs {
                return lhsText == rhsText
            }
            return false
        }
    }
    
    static func <(lhs: WhiteGramOtherTranscriptionServiceSelectionEntry, rhs: WhiteGramOtherTranscriptionServiceSelectionEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! WhiteGramOtherTranscriptionServiceSelectionArguments
        
        switch self {
        case let .service(service, selected):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                systemStyle: .glass,
                icon: selected ? whiteGramSelectionCheckIcon(color: presentationData.theme.list.itemAccentColor) : whiteGramSelectionEmptyIcon(),
                title: service.title,
                label: "",
                sectionId: self.section,
                style: .blocks,
                disclosureStyle: .none,
                action: {
                    arguments.selectService(service)
                }
            )
            
        case let .info(text):
            return ItemListTextItem(
                presentationData: presentationData,
                text: .plain(text),
                sectionId: self.section
            )
        }
    }
}

private final class WhiteGramOtherTranscriptionServiceSelectionArguments {
    let selectService: (WhiteGramOtherTranscriptionService) -> Void
    
    init(selectService: @escaping (WhiteGramOtherTranscriptionService) -> Void) {
        self.selectService = selectService
    }
}

private func whiteGramOtherTranscriptionServiceSelectionEntries(state: WhiteGramOtherSettingsState) -> [WhiteGramOtherTranscriptionServiceSelectionEntry] {
    return [
        .service(.telegram, state.transcriptionService == .telegram),
        .service(.apple, state.transcriptionService == .apple),
        .info("WhiteGram будет использовать Apple, если Telegram будет недоступен.")
    ]
}

private func whiteGramOtherTranscriptionServiceController(
    context: AccountContext,
    statePromise: ValuePromise<WhiteGramOtherSettingsState>,
    updateService: @escaping (WhiteGramOtherTranscriptionService) -> Void
) -> ViewController {
    let arguments = WhiteGramOtherTranscriptionServiceSelectionArguments(
        selectService: { service in
            updateService(service)
        }
    )
    
    let signal: Signal<(ItemListControllerState, (ItemListNodeState, WhiteGramOtherTranscriptionServiceSelectionArguments)), NoError> = combineLatest(
        context.sharedContext.presentationData,
        statePromise.get()
    )
    |> deliverOnMainQueue
    |> map { presentationData, state -> (ItemListControllerState, (ItemListNodeState, WhiteGramOtherTranscriptionServiceSelectionArguments)) in
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Сервис транскрипции"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: whiteGramOtherTranscriptionServiceSelectionEntries(state: state),
            style: .blocks,
            animateChanges: true
        )
        
        return (controllerState, (listState, arguments))
    }
    
    return ItemListController(context: context, state: signal)
}