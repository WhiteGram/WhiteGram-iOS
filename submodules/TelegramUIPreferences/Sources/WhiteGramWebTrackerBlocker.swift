import Foundation

#if canImport(WebKit)
import WebKit

private let whiteGramWebTrackerRuleListIdentifier = "WhiteGramWebTrackerBlocker.v1"

public func whiteGramWebTrackerContentRuleListJSON() -> String {
    let blockedHosts = [
        "google-analytics\\.com",
        "googletagmanager\\.com",
        "mc\\.yandex\\.ru",
        "privacy-cs\\.mail\\.ru",
        "sdk-api\\.apptracer\\.ru",
        "tns-counter\\.ru",
        "sentry\\.io"
    ]
    
    let rule: [String: Any] = [
        "trigger": [
            "url-filter": "^https?://([^/:]*\\.)?(\(blockedHosts.joined(separator: "|")))([:/]|$)",
            "resource-type": [
                "document",
                "image",
                "style-sheet",
                "script",
                "font",
                "raw",
                "svg-document",
                "media",
                "popup"
            ]
        ],
        "action": [
            "type": "block"
        ]
    ]
    
    guard let data = try? JSONSerialization.data(withJSONObject: [rule], options: []), let string = String(data: data, encoding: .utf8) else {
        return "[]"
    }
    return string
}

public func whiteGramInstallWebTrackerBlocker(into contentController: WKUserContentController) {
    if #available(iOS 11.0, *) {
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: whiteGramWebTrackerRuleListIdentifier,
            encodedContentRuleList: whiteGramWebTrackerContentRuleListJSON(),
            completionHandler: { ruleList, _ in
                if let ruleList = ruleList {
                    DispatchQueue.main.async {
                        contentController.add(ruleList)
                    }
                }
            }
        )
    }
}
#endif
