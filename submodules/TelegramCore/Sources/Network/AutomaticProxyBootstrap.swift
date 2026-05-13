import Foundation
import SwiftSignalKit
import Postbox
import MtProtoKit

private let automaticProxyBootstrapSources: [String] = [
    "https://raw.githubusercontent.com/SoliSpirit/mtproto/master/all_proxies.txt"
]

private let automaticProxyRefreshInterval: Double = 10.0 * 60.0
private let automaticProxyActivationDelay: Double = 4.0
private let automaticProxyBestSelectionDelay: Double = 0.5
private let automaticProxyConnectionFallbackDelay: Double = 12.0
private let automaticProxyProbeServerLimit = 40
private let automaticProxyStoredServerLimit = 40

private func automaticProxyHostIsIPAddress(_ host: String) -> Bool {
    let normalizedHost = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
    let ipv4Parts = normalizedHost.split(separator: ".", omittingEmptySubsequences: false)
    if ipv4Parts.count == 4 {
        var isIPv4 = true
        for part in ipv4Parts {
            guard let value = Int(part), value >= 0 && value <= 255, String(value) == String(part) else {
                isIPv4 = false
                break
            }
        }
        if isIPv4 {
            return true
        }
    }
    
    if normalizedHost.contains(":") {
        let allowed = CharacterSet(charactersIn: "0123456789abcdefABCDEF:")
        return !normalizedHost.isEmpty && normalizedHost.rangeOfCharacter(from: allowed.inverted) == nil
    }
    
    return false
}

private func automaticProxyHostIsDomainName(_ host: String) -> Bool {
    let normalizedHost = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).trimmingCharacters(in: CharacterSet(charactersIn: "."))
    if normalizedHost.isEmpty || automaticProxyHostIsIPAddress(normalizedHost) {
        return false
    }
    
    let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-.")
    if normalizedHost.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
        return false
    }
    
    let labels = normalizedHost.split(separator: ".", omittingEmptySubsequences: false)
    if labels.count < 2 {
        return false
    }
    
    for label in labels {
        if label.isEmpty || label.count > 63 || label.hasPrefix("-") || label.hasSuffix("-") {
            return false
        }
    }
    
    return true
}

private func automaticProxyFetchSource(_ source: String) -> Signal<String, NoError> {
    return Signal { subscriber in
        guard let url = URL(string: source) else {
            subscriber.putCompletion()
            return EmptyDisposable
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15.0
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, _, _ in
            if let data = data, let text = String(data: data, encoding: .utf8) {
                subscriber.putNext(text)
            }
            subscriber.putCompletion()
        })
        task.resume()
        
        return ActionDisposable {
            task.cancel()
        }
    }
}

private func automaticProxyParseServers(_ text: String) -> [ProxyServerSettings] {
    var result: [ProxyServerSettings] = []
    var seen = Set<ProxyServerSettings>()
    
    let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\"'<>"))
    for rawToken in text.components(separatedBy: separators) {
        let token = rawToken.trimmingCharacters(in: CharacterSet(charactersIn: ".,;()[]{}"))
        guard token.hasPrefix("https://t.me/proxy?") || token.hasPrefix("http://t.me/proxy?") || token.hasPrefix("tg://proxy?") else {
            continue
        }
        guard let components = URLComponents(string: token), let queryItems = components.queryItems else {
            continue
        }
        
        var host: String?
        var port: Int32?
        var secret: Data?
        for item in queryItems {
            switch item.name {
            case "server":
                host = item.value?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "."))
            case "port":
                if let value = item.value, let parsed = Int32(value) {
                    port = abs(parsed)
                }
            case "secret":
                if let value = item.value, let parsedSecret = MTProxySecret.parse(value) {
                    secret = parsedSecret.serialize()
                }
            default:
                break
            }
        }
        
        if let host = host, !host.isEmpty, automaticProxyHostIsDomainName(host), let port = port, port > 0, port <= 65535, let secret = secret {
            let server = ProxyServerSettings(host: host, port: port, connection: .mtp(secret: secret))
            if !seen.contains(server) {
                seen.insert(server)
                result.append(server)
            }
        }
    }
    
    return result
}

private func automaticProxyMergedServers(existing: [ProxyServerSettings], fetched: [ProxyServerSettings], limit: Int = automaticProxyStoredServerLimit) -> [ProxyServerSettings] {
    var result: [ProxyServerSettings] = []
    var seen = Set<ProxyServerSettings>()
    
    for server in existing {
        if !seen.contains(server) {
            seen.insert(server)
            result.append(server)
        }
    }
    for server in fetched {
        if !seen.contains(server) {
            seen.insert(server)
            result.append(server)
        }
    }
    
    if result.count > limit {
        result = Array(result.prefix(limit))
    }
    return result
}

private func automaticProxyManualServers(settings: ProxySettings, fetchedServers: [ProxyServerSettings]) -> [ProxyServerSettings] {
    let automaticSet = Set(settings.automaticServers)
    let fetchedSet = Set(fetchedServers)
    let migrateLegacyAutomaticServers = automaticSet.isEmpty && settings.autoConnectOnLaunch && settings.servers.count >= automaticProxyStoredServerLimit / 2
    return settings.servers.filter { server in
        if automaticSet.contains(server) {
            return false
        }
        if fetchedSet.contains(server) {
            return false
        }
        if migrateLegacyAutomaticServers, case .mtp = server.connection, automaticProxyHostIsDomainName(server.host) {
            return false
        }
        return true
    }
}

private func automaticProxyCleanupActiveServer(settings: inout ProxySettings) {
    if let activeServer = settings.activeServer, !settings.servers.contains(activeServer) {
        settings.activeServer = nil
        if settings.enabled && !settings.autoConnectOnLaunch {
            settings.enabled = false
        }
    }
}

private func automaticProxySortedAvailableServers(candidates: [ProxyServerSettings], statuses: [ProxyServerSettings: ProxyServerStatus], excluding excludedServer: ProxyServerSettings? = nil) -> [ProxyServerSettings] {
    var availableServers: [(ProxyServerSettings, Double)] = []
    for server in candidates {
        if let excludedServer = excludedServer, server == excludedServer {
            continue
        }
        if case let .available(rtt)? = statuses[server] {
            availableServers.append((server, rtt))
        }
    }
    availableServers.sort { lhs, rhs in
        return lhs.1 < rhs.1
    }
    return availableServers.map { $0.0 }
}

private final class AutomaticProxyBootstrapContext {
    private let accountManager: AccountManager<TelegramAccountManagerTypes>
    private let network: Network
    private let queue = Queue()
    
    private let fetchedServers = Promise<[ProxyServerSettings]>([])
    private let candidateServers = Promise<[ProxyServerSettings]>([])
    
    private var fetchDisposable: Disposable?
    private var settingsDisposable: Disposable?
    private var statusDisposable: Disposable?
    private var connectionStatusDisposable: Disposable?
    private var refreshTimer: SwiftSignalKit.Timer?
    private var activationTimer: SwiftSignalKit.Timer?
    private var bestSelectionTimer: SwiftSignalKit.Timer?
    private var connectionFallbackTimer: SwiftSignalKit.Timer?
    
    private var currentSettings: ProxySettings = .defaultSettings
    private var currentStatuses: [ProxyServerSettings: ProxyServerStatus] = [:]
    private var currentCandidates: [ProxyServerSettings] = []
    private var currentFetchedServers: [ProxyServerSettings] = []
    private var lastStoredAvailableServers: [ProxyServerSettings] = []
    private var lastStoredFetchedServers: [ProxyServerSettings] = []
    private var excludedActiveServer: ProxyServerSettings?
    private var proxyNeeded = false
    
    init(accountManager: AccountManager<TelegramAccountManagerTypes>, network: Network) {
        self.accountManager = accountManager
        self.network = network
    }
    
    func start() {
        let settingsSignal = self.accountManager.sharedData(keys: [SharedDataKeys.proxySettings])
        |> map { sharedData -> ProxySettings in
            return sharedData.entries[SharedDataKeys.proxySettings]?.get(ProxySettings.self) ?? ProxySettings.defaultSettings
        }
        
        self.settingsDisposable = (combineLatest(settingsSignal, self.fetchedServers.get())
        |> deliverOn(self.queue)).start(next: { [weak self] settings, fetchedServers in
            guard let strongSelf = self else {
                return
            }
            strongSelf.currentSettings = settings
            strongSelf.currentFetchedServers = fetchedServers
            let candidates = automaticProxyMergedServers(existing: settings.servers, fetched: Array(fetchedServers.prefix(automaticProxyProbeServerLimit)), limit: automaticProxyProbeServerLimit)
            strongSelf.currentCandidates = candidates
            strongSelf.candidateServers.set(.single(candidates))
        })
        
        let statuses = ProxyServersStatuses(network: self.network, servers: self.candidateServers.get())
        self.statusDisposable = (statuses.statuses()
        |> deliverOn(self.queue)).start(next: { [weak self] statuses in
            guard let strongSelf = self else {
                return
            }
            strongSelf.currentStatuses = statuses
            strongSelf.storeAvailableFetchedServersIfNeeded()
            if strongSelf.currentSettings.enabled && (strongSelf.currentSettings.autoConnectOnLaunch || strongSelf.proxyNeeded) {
                if let activeServer = strongSelf.currentSettings.activeServer, case .notAvailable? = statuses[activeServer] {
                    strongSelf.excludedActiveServer = activeServer
                    strongSelf.proxyNeeded = true
                }
                strongSelf.scheduleBestProxySelection()
            }
        })
        
        self.connectionStatusDisposable = (self.network.connectionStatus
        |> deliverOn(self.queue)).start(next: { [weak self] status in
            self?.connectionStatusUpdated(status)
        })
        
        self.refreshProxyList()
        self.refreshTimer = SwiftSignalKit.Timer(timeout: automaticProxyRefreshInterval, repeat: true, completion: { [weak self] in
            self?.refreshProxyList()
        }, queue: self.queue)
        self.refreshTimer?.start()
    }
    
    func dispose() {
        self.fetchDisposable?.dispose()
        self.settingsDisposable?.dispose()
        self.statusDisposable?.dispose()
        self.connectionStatusDisposable?.dispose()
        self.refreshTimer?.invalidate()
        self.activationTimer?.invalidate()
        self.bestSelectionTimer?.invalidate()
        self.connectionFallbackTimer?.invalidate()
    }
    
    private func refreshProxyList() {
        self.fetchDisposable?.dispose()
        
        var sourceSignals: [Signal<String, NoError>] = []
        for source in automaticProxyBootstrapSources {
            sourceSignals.append(automaticProxyFetchSource(source))
        }
        
        self.fetchDisposable = (combineLatest(sourceSignals)
        |> map { texts -> [ProxyServerSettings] in
            var servers: [ProxyServerSettings] = []
            var seen = Set<ProxyServerSettings>()
            for text in texts {
                for server in automaticProxyParseServers(text) {
                    if !seen.contains(server) {
                        seen.insert(server)
                        servers.append(server)
                    }
                }
            }
            return servers
        }
        |> deliverOn(self.queue)).start(next: { [weak self] servers in
            guard let strongSelf = self, !servers.isEmpty else {
                return
            }
            strongSelf.fetchedServers.set(.single(servers))
            strongSelf.storeFetchedServersIfNeeded(servers)
        })
    }
    
    private func storeFetchedServersIfNeeded(_ servers: [ProxyServerSettings]) {
        let fetchedServers = Array(servers.prefix(automaticProxyStoredServerLimit))
        if fetchedServers.isEmpty || fetchedServers == self.lastStoredFetchedServers {
            return
        }
        self.lastStoredFetchedServers = fetchedServers
        
        let _ = (updateProxySettingsInteractively(accountManager: self.accountManager, { settings in
            var settings = settings
            let manualServers = automaticProxyManualServers(settings: settings, fetchedServers: fetchedServers)
            settings.servers = automaticProxyMergedServers(existing: fetchedServers, fetched: manualServers)
            settings.automaticServers = fetchedServers
            if let activeServer = settings.activeServer, automaticProxyHostIsIPAddress(activeServer.host) {
                settings.activeServer = nil
                settings.enabled = false
            }
            automaticProxyCleanupActiveServer(settings: &settings)
            return settings
        })).start()
    }
    
    private func storeAvailableFetchedServersIfNeeded() {
        let fetchedSet = Set(self.currentFetchedServers)
        let statuses = self.currentStatuses
        var autoAvailableServers: [ProxyServerSettings] = []
        for server in automaticProxySortedAvailableServers(candidates: self.currentCandidates, statuses: statuses) {
            if fetchedSet.contains(server) {
                autoAvailableServers.append(server)
            }
        }
        
        guard !autoAvailableServers.isEmpty else {
            return
        }
        
        if autoAvailableServers == self.lastStoredAvailableServers {
            return
        }
        self.lastStoredAvailableServers = autoAvailableServers
        
        let _ = (updateProxySettingsInteractively(accountManager: self.accountManager, { settings in
            var settings = settings
            let automaticSet = Set(settings.automaticServers)
            let existingServers = settings.servers.filter { server in
                if automaticSet.contains(server) && !fetchedSet.contains(server) {
                    return false
                }
                if fetchedSet.contains(server), case .notAvailable? = statuses[server] {
                    return false
                }
                return true
            }
            let mergedServers = automaticProxyMergedServers(existing: autoAvailableServers, fetched: existingServers)
            settings.servers = mergedServers
            settings.automaticServers = settings.automaticServers.filter { fetchedSet.contains($0) }
            if settings.enabled && settings.autoConnectOnLaunch {
                settings.activeServer = automaticProxySortedAvailableServers(candidates: mergedServers, statuses: statuses).first
            }
            automaticProxyCleanupActiveServer(settings: &settings)
            return settings
        })).start()
    }
    
    private func connectionStatusUpdated(_ status: ConnectionStatus) {
        switch status {
        case .online:
            self.proxyNeeded = false
            self.excludedActiveServer = nil
            self.activationTimer?.invalidate()
            self.activationTimer = nil
            self.connectionFallbackTimer?.invalidate()
            self.connectionFallbackTimer = nil
        case let .connecting(proxyAddress, proxyHasConnectionIssues):
            if proxyHasConnectionIssues {
                self.excludedActiveServer = self.currentSettings.activeServer
            }
            if self.currentSettings.enabled && self.currentSettings.autoConnectOnLaunch {
                if proxyAddress == nil || proxyHasConnectionIssues {
                    self.scheduleProxyActivation()
                } else {
                    self.scheduleConnectionFallback()
                }
            }
        case .waitingForNetwork, .updating:
            if self.currentSettings.enabled && self.currentSettings.autoConnectOnLaunch {
                self.scheduleProxyActivation()
            }
        }
    }
    
    private func scheduleProxyActivation() {
        if self.activationTimer != nil {
            return
        }
        self.activationTimer = SwiftSignalKit.Timer(timeout: automaticProxyActivationDelay, repeat: false, completion: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.activationTimer = nil
            strongSelf.proxyNeeded = true
            strongSelf.scheduleBestProxySelection()
        }, queue: self.queue)
        self.activationTimer?.start()
    }
    
    private func scheduleConnectionFallback() {
        if self.connectionFallbackTimer != nil {
            return
        }
        let activeServer = self.currentSettings.activeServer
        self.connectionFallbackTimer = SwiftSignalKit.Timer(timeout: automaticProxyConnectionFallbackDelay, repeat: false, completion: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.connectionFallbackTimer = nil
            guard strongSelf.currentSettings.enabled && strongSelf.currentSettings.autoConnectOnLaunch else {
                return
            }
            if let activeServer = activeServer, strongSelf.currentSettings.activeServer == activeServer {
                strongSelf.excludedActiveServer = activeServer
            }
            strongSelf.proxyNeeded = true
            strongSelf.scheduleBestProxySelection()
        }, queue: self.queue)
        self.connectionFallbackTimer?.start()
    }
    
    private func scheduleBestProxySelection() {
        self.bestSelectionTimer?.invalidate()
        self.bestSelectionTimer = SwiftSignalKit.Timer(timeout: automaticProxyBestSelectionDelay, repeat: false, completion: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.bestSelectionTimer = nil
            if strongSelf.currentSettings.enabled && (strongSelf.currentSettings.autoConnectOnLaunch || strongSelf.proxyNeeded) {
                strongSelf.activateBestProxyIfNeeded()
            }
        }, queue: self.queue)
        self.bestSelectionTimer?.start()
    }
    
    private func activateBestProxyIfNeeded() {
        guard self.currentSettings.enabled else {
            return
        }
        guard let bestServer = self.bestAvailableServer() else {
            self.refreshProxyList()
            return
        }
        if self.currentSettings.enabled && self.currentSettings.activeServer == bestServer {
            return
        }
        
        let _ = (updateProxySettingsInteractively(accountManager: self.accountManager, { settings in
            var settings = settings
            guard settings.enabled else {
                return settings
            }
            settings.servers = automaticProxyMergedServers(existing: settings.servers, fetched: [bestServer])
            if self.currentFetchedServers.contains(bestServer) && !settings.automaticServers.contains(bestServer) {
                settings.automaticServers.append(bestServer)
            }
            settings.activeServer = bestServer
            return settings
        })).start()
    }
    
    private func bestAvailableServer() -> ProxyServerSettings? {
        return automaticProxySortedAvailableServers(candidates: self.currentSettings.servers, statuses: self.currentStatuses, excluding: self.excludedActiveServer).first
    }
}

func managedAutomaticProxyBootstrap(accountManager: AccountManager<TelegramAccountManagerTypes>, network: Network) -> Disposable {
    let context = AutomaticProxyBootstrapContext(accountManager: accountManager, network: network)
    context.start()
    return ActionDisposable {
        context.dispose()
    }
}
