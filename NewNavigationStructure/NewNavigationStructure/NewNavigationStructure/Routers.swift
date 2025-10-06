import SwiftUI
import OSLog

// Lightweight storage for route tokens
private enum RouteStorage {
    static func saveEncodable<T: Encodable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadDecodable<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }

    // Legacy support: load previously stored string tokens
    static func loadLegacyStrings(forKey key: String) -> [String]? {
        UserDefaults.standard.stringArray(forKey: key)
    }

    static func clear(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// Unified storage keys for routers
private enum RouterStorageKey {
    static let authPath = "router.auth.path"
    static let tab1Path = "router.tab1.path"
    static let tab2Path = "router.tab2.path"
    static let tab3Path = "router.tab3.path"
    static let tab3Modal = "router.tab3.modal"
    static let tab3FullScreen = "router.tab3.fullscreen"
}

// Centralized logger for router-related events
private enum RouterLog {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Routers", category: "Navigation")
}

// Logout broadcast
extension Notification.Name {
    static let routerDidLogout = Notification.Name("router.didLogout")
}

protocol Router: ObservableObject {
    associatedtype Path: Hashable
    var path: [Path] { get set }
    func push(_ route: Path)
    func pop()
    func popTo(_ route: Path)
    func navigateTo(_ route: Path)
}

final class AuthRouter: Router {
    @Published var path: [AuthPath] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: RouterStorageKey.authPath) }
    }

    init() {
        if let tokens = RouteStorage.loadDecodable([AuthRouteToken].self, forKey: RouterStorageKey.authPath) {
            self.path = decode(tokens)
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.authPath) {
            self.path = legacyDecode(legacy)
            RouteStorage.saveEncodable(encode(self.path), forKey: RouterStorageKey.authPath)
            RouterLog.logger.info("Migrated legacy auth path to Codable format")
        }
    }

    func push(_ route: AuthPath) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popTo(_ route: AuthPath) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else if route == .login {
            clearPersistence()
            NotificationCenter.default.post(name: .routerDidLogout, object: nil)
        }
    }

    func navigateTo(_ route: AuthPath) {
        path = [route]
    }

    private enum AuthRouteToken: String, Codable { case login, validation }

    private func encode(_ path: [AuthPath]) -> [AuthRouteToken] {
        path.map { route in
            switch route {
            case .login: return .login
            case .validation: return .validation
            }
        }
    }

    private func decode(_ tokens: [AuthRouteToken]) -> [AuthPath] {
        tokens.map { token in
            switch token {
            case .login: return .login
            case .validation: return .validation
            }
        }
    }

    private func legacyDecode(_ tokens: [String]) -> [AuthPath] {
        tokens.compactMap { token in
            switch token {
            case "login": return .login
            case "validation": return .validation
            default: return nil
            }
        }
    }

    func clearPersistence() {
        RouteStorage.clear(forKey: RouterStorageKey.authPath)
        self.path = []
    }
}

final class Tab1Router: Router {
    // Provide hooks to extract a stable ID from ApiCustomers and resolve it back.
    // Example:
    // Tab1Router.detailIDExtractor = { $0.id }
    // Tab1Router.detailResolver = { id in ApiCustomers(id: id, ...) }
    static var detailIDExtractor: ((ApiCustomers) -> String)?
    static var detailResolver: ((String) -> ApiCustomers)?

    private var logoutObserver: Any?

    @Published var path: [Tab1Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: RouterStorageKey.tab1Path) }
    }

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab1RouteToken].self, forKey: RouterStorageKey.tab1Path) {
            self.path = decode(tokens)
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.tab1Path) {
            self.path = legacyDecode(legacy)
            RouteStorage.saveEncodable(encode(self.path), forKey: RouterStorageKey.tab1Path)
            RouterLog.logger.info("Migrated legacy tab1 path to Codable format")
        }
        logoutObserver = NotificationCenter.default.addObserver(forName: .routerDidLogout, object: nil, queue: .main) { [weak self] _ in
            self?.clearPersistence()
        }
    }

    deinit {
        if let o = logoutObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    func push(_ route: Tab1Path) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] {
                path = []
            }
        }
    }

    func popTo(_ route: Tab1Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else if route == .screen1 {
            path = []
        }
    }

    func navigateTo(_ route: Tab1Path) {
        if route == .screen1 {
            path = []
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else {
            path = buildPath(to: route)
        }
    }

    private func buildPath(to route: Tab1Path) -> [Tab1Path] {
        switch route {
        case .screen1:
            return [.screen1]
        case .screen2:
            return [.screen1, .screen2]
        case .detail(let c):
            return [.screen1, .screen2, .detail(c)]
        }
    }

    private enum Tab1RouteToken: Codable {
        case screen1
        case screen2
        case detail(id: String)
    }

    private func encode(_ path: [Tab1Path]) -> [Tab1RouteToken] {
        path.compactMap { route in
            switch route {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .detail(let customer):
                if let id = Self.detailIDExtractor?(customer) {
                    return .detail(id: id)
                } else {
                    return nil
                }
            }
        }
    }

    private func decode(_ tokens: [Tab1RouteToken]) -> [Tab1Path] {
        tokens.compactMap { token in
            switch token {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .detail(let id):
                if let resolver = Self.detailResolver {
                    return .detail(resolver(id))
                } else {
                    // Fallback: without resolver, return to the parent screen.
                    return .screen2
                }
            }
        }
    }

    private func legacyDecode(_ tokens: [String]) -> [Tab1Path] {
        tokens.compactMap { token in
            switch token {
            case "screen1": return .screen1
            case "screen2": return .screen2
            default: return nil
            }
        }
    }

    func clearPersistence() {
        RouteStorage.clear(forKey: RouterStorageKey.tab1Path)
        self.path = []
    }
}

final class Tab2Router: Router {
    private var logoutObserver: Any?

    @Published var path: [Tab2Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: RouterStorageKey.tab2Path) }
    }

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab2RouteToken].self, forKey: RouterStorageKey.tab2Path) {
            self.path = decode(tokens)
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.tab2Path) {
            self.path = legacyDecode(legacy)
            RouteStorage.saveEncodable(encode(self.path), forKey: RouterStorageKey.tab2Path)
            RouterLog.logger.info("Migrated legacy tab2 path to Codable format")
        }
        logoutObserver = NotificationCenter.default.addObserver(forName: .routerDidLogout, object: nil, queue: .main) { [weak self] _ in
            self?.clearPersistence()
        }
    }

    deinit {
        if let o = logoutObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    func push(_ route: Tab2Path) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] {
                path = []
            }
        }
    }

    func popTo(_ route: Tab2Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else if route == .screen1 {
            path = []
        }
    }

    func navigateTo(_ route: Tab2Path) {
        if route == .screen1 {
            path = []
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else {
            path = buildPath(to: route)
        }
    }

    private func buildPath(to route: Tab2Path) -> [Tab2Path] {
        switch route {
        case .screen1:
            return [.screen1]
        case .screen2:
            return [.screen1, .screen2]
        case .screen2Detail(let id):
            return [.screen1, .screen2, .screen2Detail(id)]
        case .screen3:
            return [.screen1, .screen2, .screen3]
        }
    }

    private enum Tab2RouteToken: Codable {
        case screen1
        case screen2
        case screen2Detail(id: String)
        case screen3
    }

    private func encode(_ path: [Tab2Path]) -> [Tab2RouteToken] {
        path.map { route in
            switch route {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .screen2Detail(let id): return .screen2Detail(id: id)
            case .screen3: return .screen3
            }
        }
    }

    private func decode(_ tokens: [Tab2RouteToken]) -> [Tab2Path] {
        tokens.map { token in
            switch token {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .screen2Detail(let id): return .screen2Detail(id)
            case .screen3: return .screen3
            }
        }
    }

    private func legacyDecode(_ tokens: [String]) -> [Tab2Path] {
        tokens.compactMap { token in
            if token == "screen1" { return .screen1 }
            if token == "screen2" { return .screen2 }
            if token == "screen3" { return .screen3 }
            if token.hasPrefix("screen2Detail:") {
                let id = String(token.dropFirst("screen2Detail:".count))
                return .screen2Detail(id)
            }
            return nil
        }
    }

    func clearPersistence() {
        RouteStorage.clear(forKey: RouterStorageKey.tab2Path)
        self.path = []
    }
}

final class Tab3Router: Router {
    private var logoutObserver: Any?

    @Published var path: [Tab3Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: RouterStorageKey.tab3Path) }
    }
    @Published var modal: Tab3Modal? {
        didSet {
            if let modal = modal {
                RouteStorage.saveEncodable(encode(modal), forKey: RouterStorageKey.tab3Modal)
            } else {
                RouteStorage.clear(forKey: RouterStorageKey.tab3Modal)
            }
        }
    }
    @Published var fullScreen: Tab3Modal? {
        didSet {
            if let full = fullScreen {
                RouteStorage.saveEncodable(encode(full), forKey: RouterStorageKey.tab3FullScreen)
            } else {
                RouteStorage.clear(forKey: RouterStorageKey.tab3FullScreen)
            }
        }
    }

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab3RouteToken].self, forKey: RouterStorageKey.tab3Path) {
            self.path = decode(tokens)
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.tab3Path) {
            self.path = legacyDecode(legacy)
            RouteStorage.saveEncodable(encode(self.path), forKey: RouterStorageKey.tab3Path)
            RouterLog.logger.info("Migrated legacy tab3 path to Codable format")
        }
        if let token = RouteStorage.loadDecodable(Tab3ModalToken.self, forKey: RouterStorageKey.tab3Modal), let m = decodeModal(token) {
            self.modal = m
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.tab3Modal)?.first, let m = legacyDecodeModal(legacy) {
            self.modal = m
            RouteStorage.saveEncodable(encode(m), forKey: RouterStorageKey.tab3Modal)
            RouterLog.logger.info("Migrated legacy tab3 modal to Codable format")
        }
        if let token = RouteStorage.loadDecodable(Tab3ModalToken.self, forKey: RouterStorageKey.tab3FullScreen), let fs = decodeModal(token) {
            self.fullScreen = fs
        } else if let legacy = RouteStorage.loadLegacyStrings(forKey: RouterStorageKey.tab3FullScreen)?.first, let fs = legacyDecodeModal(legacy) {
            self.fullScreen = fs
            RouteStorage.saveEncodable(encode(fs), forKey: RouterStorageKey.tab3FullScreen)
            RouterLog.logger.info("Migrated legacy tab3 fullScreen to Codable format")
        }
        logoutObserver = NotificationCenter.default.addObserver(forName: .routerDidLogout, object: nil, queue: .main) { [weak self] _ in
            self?.clearPersistence()
        }
    }

    deinit {
        if let o = logoutObserver {
            NotificationCenter.default.removeObserver(o)
        }
    }

    func push(_ route: Tab3Path) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] {
                path = []
            }
        }
    }

    func popTo(_ route: Tab3Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else if route == .screen1 {
            path = []
        }
    }

    func navigateTo(_ route: Tab3Path) {
        if route == .screen1 {
            path = []
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else {
            path = buildPath(to: route)
        }
    }

    // MARK: - Modal helpers
    func present(_ modal: Tab3Modal) { self.modal = modal }
    func presentFullScreen(_ modal: Tab3Modal) { self.fullScreen = modal }
    func dismissModal() { self.modal = nil }
    func dismissFullScreen() { self.fullScreen = nil }

    private func buildPath(to route: Tab3Path) -> [Tab3Path] {
        switch route {
        case .screen1:
            return [.screen1]
        case .screen2:
            return [.screen1, .screen2]
        case .screen2Detail(let id):
            return [.screen1, .screen2, .screen2Detail(id)]
        case .screen2Edit(let id):
            return [.screen1, .screen2, .screen2Detail(id), .screen2Edit(id)]
        case .screen3:
            return [.screen1, .screen2, .screen3]
        case .screen4:
            return [.screen1, .screen2, .screen3, .screen4]
        case .screen5:
            return [.screen1, .screen2, .screen3, .screen4, .screen5]
        case .screen6:
            return [.screen1, .screen2, .screen3, .screen4, .screen5, .screen6]
        }
    }

    private enum Tab3RouteToken: Codable {
        case screen1
        case screen2
        case screen2Detail(id: String)
        case screen2Edit(id: String)
        case screen3
        case screen4
        case screen5
        case screen6
    }

    private enum Tab3ModalToken: String, Codable { case createItem, filter }

    private func encode(_ path: [Tab3Path]) -> [Tab3RouteToken] {
        path.map { route in
            switch route {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .screen2Detail(let id): return .screen2Detail(id: id)
            case .screen2Edit(let id): return .screen2Edit(id: id)
            case .screen3: return .screen3
            case .screen4: return .screen4
            case .screen5: return .screen5
            case .screen6: return .screen6
            }
        }
    }

    private func decode(_ tokens: [Tab3RouteToken]) -> [Tab3Path] {
        tokens.map { token in
            switch token {
            case .screen1: return .screen1
            case .screen2: return .screen2
            case .screen2Detail(let id): return .screen2Detail(id)
            case .screen2Edit(let id): return .screen2Edit(id)
            case .screen3: return .screen3
            case .screen4: return .screen4
            case .screen5: return .screen5
            case .screen6: return .screen6
            }
        }
    }

    private func encode(_ modal: Tab3Modal) -> Tab3ModalToken {
        switch modal {
        case .createItem: return .createItem
        case .filter: return .filter
        }
    }

    private func decodeModal(_ token: Tab3ModalToken) -> Tab3Modal? {
        switch token {
        case .createItem: return .createItem
        case .filter: return .filter
        }
    }

    private func legacyDecode(_ tokens: [String]) -> [Tab3Path] {
        tokens.compactMap { token in
            switch token {
            case "screen1": return .screen1
            case "screen2": return .screen2
            case "screen3": return .screen3
            case "screen4": return .screen4
            case "screen5": return .screen5
            case "screen6": return .screen6
            default:
                if token.hasPrefix("screen2Detail:") {
                    let id = String(token.dropFirst("screen2Detail:".count))
                    return .screen2Detail(id)
                }
                if token.hasPrefix("screen2Edit:") {
                    let id = String(token.dropFirst("screen2Edit:".count))
                    return .screen2Edit(id)
                }
                return nil
            }
        }
    }

    private func legacyDecodeModal(_ token: String) -> Tab3Modal? {
        switch token {
        case "createItem": return .createItem
        case "filter": return .filter
        default: return nil
        }
    }

    func clearPersistence() {
        RouteStorage.clear(forKey: RouterStorageKey.tab3Path)
        RouteStorage.clear(forKey: RouterStorageKey.tab3Modal)
        RouteStorage.clear(forKey: RouterStorageKey.tab3FullScreen)
        self.path = []
        self.modal = nil
        self.fullScreen = nil
    }
}

protocol EditableDetailRouter: Router where Path == Tab3Path {
    func pushEdit(_ id: String)
}

extension Tab3Router: EditableDetailRouter {
    func pushEdit(_ id: String) { push(.screen2Edit(id)) }
}

// MARK: - Paths

enum AuthPath: Hashable {
    case login
    case validation
}

enum Tab1Path: Hashable {
    case screen1
    case screen2
    case detail(ApiCustomers)
}

enum Tab2Path: Hashable {
    case screen1
    case screen2
    case screen2Detail(String)
    case screen3
}

enum Tab3Modal: Identifiable, Hashable {
    case createItem
    case filter

    var id: String {
        switch self {
        case .createItem: return "createItem"
        case .filter: return "filter"
        }
    }
}

enum Tab3Path: Hashable {
    case screen1
    case screen2
    case screen2Detail(String)
    case screen2Edit(String)
    case screen3
    case screen4
    case screen5
    case screen6
}
