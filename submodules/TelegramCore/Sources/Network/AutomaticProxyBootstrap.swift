import Foundation
import SwiftSignalKit
import Postbox
import MtProtoKit

private let automaticProxyBootstrapSources: [String] = [
    "https://raw.githubusercontent.com/SoliSpirit/mtproto/master/all_proxies.txt"
]

private let automaticProxyRefreshInterval: Double = 30.0 * 60.0
private let automaticProxyActivationDelay: Double = 8.0
private let automaticProxyProbeServerLimit = 120
private let automaticProxyStoredServerLimit = 40

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
        
        if let host = host, !host.isEmpty, let port = port, port > 0, let secret = secret {
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
    
    private var currentSettings: ProxySettings = .defaultSettings
    private var currentStatuses: [ProxyServerSettings: ProxyServerStatus] = [:]
    private var currentCandidates: [ProxyServerSettings] = []
    private var currentFetchedServers: [ProxyServerSettings] = []
    private var lastStoredAvailableServers: [ProxyServerSettings] = []
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
            if strongSelf.proxyNeeded {
                strongSelf.activateBestProxyIfNeeded()
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
        })
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
        
        var hasStoredUnavailableFetchedServer = false
        for server in self.currentSettings.servers {
            if fetchedSet.contains(server), case .notAvailable? = statuses[server] {
                hasStoredUnavailableFetchedServer = true
                break
            }
        }
        
        guard !autoAvailableServers.isEmpty || hasStoredUnavailableFetchedServer else {
            return
        }
        
        if autoAvailableServers == self.lastStoredAvailableServers && !hasStoredUnavailableFetchedServer {
            return
        }
        self.lastStoredAvailableServers = autoAvailableServers
        
        let _ = (updateProxySettingsInteractively(accountManager: self.accountManager, { settings in
            var settings = settings
            
            let availableSet = Set(autoAvailableServers)
            var preservedServers: [ProxyServerSettings] = []
            var seen = Set<ProxyServerSettings>()
            
            for server in settings.servers {
                if fetchedSet.contains(server), case .notAvailable? = statuses[server], !availableSet.contains(server) {
                    continue
                }
                if !seen.contains(server) {
                    seen.insert(server)
                    preservedServers.append(server)
                }
            }
            
            settings.servers = automaticProxyMergedServers(existing: autoAvailableServers, fetched: preservedServers)
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
        case let .connecting(proxyAddress, proxyHasConnectionIssues):
            if proxyAddress == nil || proxyHasConnectionIssues {
                if proxyHasConnectionIssues {
                    self.excludedActiveServer = self.currentSettings.activeServer
                }
                self.scheduleProxyActivation()
            }
        case .waitingForNetwork, .updating:
            self.scheduleProxyActivation()
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
            strongSelf.activateBestProxyIfNeeded()
        }, queue: self.queue)
        self.activationTimer?.start()
    }
    
    private func activateBestProxyIfNeeded() {
        guard let bestServer = self.bestAvailableServer() else {
            self.refreshProxyList()
            return
        }
        if self.currentSettings.enabled && self.currentSettings.activeServer == bestServer {
            return
        }
        
        let _ = (updateProxySettingsInteractively(accountManager: self.accountManager, { settings in
            var settings = settings
            settings.servers = automaticProxyMergedServers(existing: settings.servers, fetched: [bestServer])
            settings.activeServer = bestServer
            settings.enabled = true
            return settings
        })).start()
    }
    
    private func bestAvailableServer() -> ProxyServerSettings? {
        return automaticProxySortedAvailableServers(candidates: self.currentCandidates, statuses: self.currentStatuses, excluding: self.excludedActiveServer).first
    }
}

func managedAutomaticProxyBootstrap(accountManager: AccountManager<TelegramAccountManagerTypes>, network: Network) -> Disposable {
    let context = AutomaticProxyBootstrapContext(accountManager: accountManager, network: network)
    context.start()
    return ActionDisposable {
        context.dispose()
    }
}
