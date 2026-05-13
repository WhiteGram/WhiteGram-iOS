import Foundation

public enum WhiteGramOtherTranslationService: String, CaseIterable {
    case telegram
    case gTranslate

    public var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .gTranslate:
            return "Google Translate"
        }
    }
}

public enum WhiteGramOtherTranscriptionService: String, CaseIterable {
    case telegram
    case apple

    public var title: String {
        switch self {
        case .telegram:
            return "Telegram"
        case .apple:
            return "Apple"
        }
    }
}

public struct WhiteGramOtherSettings: Equatable {
    public var autoTranslate: Bool
    public var translationService: WhiteGramOtherTranslationService
    public var translationButton: Bool

    public var voiceTranscription: Bool
    public var transcriptionService: WhiteGramOtherTranscriptionService

    public var forceDeviceMicrophone: Bool

    public var hideCameraInGallery: Bool
    public var hideCameraPreviewInGallery: Bool

    public init() {
        let defaults = UserDefaults.standard

        self.autoTranslate = defaults.object(forKey: "whitegram.other.autoTranslate") as? Bool ?? false

        if let rawValue = defaults.string(forKey: "whitegram.other.translationService"), let value = WhiteGramOtherTranslationService(rawValue: rawValue) {
            self.translationService = value
        } else {
            self.translationService = .gTranslate
        }

        self.translationButton = defaults.object(forKey: "whitegram.other.translationButton") as? Bool ?? true
        self.voiceTranscription = defaults.object(forKey: "whitegram.other.voiceTranscription") as? Bool ?? true

        if let rawValue = defaults.string(forKey: "whitegram.other.transcriptionService"), let value = WhiteGramOtherTranscriptionService(rawValue: rawValue) {
            self.transcriptionService = value
        } else {
            self.transcriptionService = .apple
        }

        self.forceDeviceMicrophone = defaults.object(forKey: "whitegram.other.forceDeviceMicrophone") as? Bool ?? false
        self.hideCameraInGallery = defaults.object(forKey: "whitegram.other.hideCameraInGallery") as? Bool ?? false
        self.hideCameraPreviewInGallery = defaults.object(forKey: "whitegram.other.hideCameraPreviewInGallery") as? Bool ?? false
    }

    public static var current: WhiteGramOtherSettings {
        return WhiteGramOtherSettings()
    }

    public mutating func setAutoTranslate(_ value: Bool) {
        self.autoTranslate = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.autoTranslate")
    }

    public mutating func setTranslationService(_ value: WhiteGramOtherTranslationService) {
        self.translationService = value
        UserDefaults.standard.set(value.rawValue, forKey: "whitegram.other.translationService")
    }

    public mutating func setTranslationButton(_ value: Bool) {
        self.translationButton = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.translationButton")
    }

    public mutating func setVoiceTranscription(_ value: Bool) {
        self.voiceTranscription = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.voiceTranscription")
    }

    public mutating func setTranscriptionService(_ value: WhiteGramOtherTranscriptionService) {
        self.transcriptionService = value
        UserDefaults.standard.set(value.rawValue, forKey: "whitegram.other.transcriptionService")
    }

    public mutating func setForceDeviceMicrophone(_ value: Bool) {
        self.forceDeviceMicrophone = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.forceDeviceMicrophone")
    }

    public mutating func setHideCameraInGallery(_ value: Bool) {
        self.hideCameraInGallery = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.hideCameraInGallery")
    }

    public mutating func setHideCameraPreviewInGallery(_ value: Bool) {
        self.hideCameraPreviewInGallery = value
        UserDefaults.standard.set(value, forKey: "whitegram.other.hideCameraPreviewInGallery")
    }
}
