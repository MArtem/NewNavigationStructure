import SwiftUI

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

    static func clear(forKey key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
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
        didSet { RouteStorage.saveEncodable(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.auth.path"

    init() {
        if let tokens = RouteStorage.loadDecodable([AuthRouteToken].self, forKey: storageKey) {
            self.path = decode(tokens)
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
            path = []
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

    func clearPersistence() {
        RouteStorage.clear(forKey: storageKey)
        self.path = []
    }
}

final class Tab1Router: Router {
    @Published var path: [Tab1Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.tab1.path"

    static var detailIDExtractor: ((ApiCustomers) -> String)?
    static var detailResolver: ((String) -> ApiCustomers)?

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab1RouteToken].self, forKey: storageKey) {
            self.path = decode(tokens)
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

    func clearPersistence() {
        RouteStorage.clear(forKey: storageKey)
        self.path = []
    }
}

final class Tab2Router: Router {
    @Published var path: [Tab2Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.tab2.path"

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab2RouteToken].self, forKey: storageKey) {
            self.path = decode(tokens)
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

    func clearPersistence() {
        RouteStorage.clear(forKey: storageKey)
        self.path = []
    }
}

final class Tab3Router: Router {
    @Published var path: [Tab3Path] = [] {
        didSet { RouteStorage.saveEncodable(encode(path), forKey: pathKey) }
    }
    @Published var modal: Tab3Modal? {
        didSet {
            if let modal = modal {
                RouteStorage.saveEncodable(encode(modal), forKey: modalKey)
            } else {
                RouteStorage.clear(forKey: modalKey)
            }
        }
    }
    @Published var fullScreen: Tab3Modal? {
        didSet {
            if let full = fullScreen {
                RouteStorage.saveEncodable(encode(full), forKey: fullScreenKey)
            } else {
                RouteStorage.clear(forKey: fullScreenKey)
            }
        }
    }

    private let pathKey = "router.tab3.path"
    private let modalKey = "router.tab3.modal"
    private let fullScreenKey = "router.tab3.fullscreen"

    init() {
        if let tokens = RouteStorage.loadDecodable([Tab3RouteToken].self, forKey: pathKey) {
            self.path = decode(tokens)
        }
        if let token = RouteStorage.loadDecodable(Tab3ModalToken.self, forKey: modalKey), let m = decodeModal(token) {
            self.modal = m
        }
        if let token = RouteStorage.loadDecodable(Tab3ModalToken.self, forKey: fullScreenKey), let fs = decodeModal(token) {
            self.fullScreen = fs
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

    func clearPersistence() {
        RouteStorage.clear(forKey: pathKey)
        RouteStorage.clear(forKey: modalKey)
        RouteStorage.clear(forKey: fullScreenKey)
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
