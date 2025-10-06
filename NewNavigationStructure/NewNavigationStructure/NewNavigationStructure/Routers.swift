import SwiftUI

// Lightweight storage for route tokens
private enum RouteStorage {
    static func save(_ tokens: [String], forKey key: String) {
        UserDefaults.standard.set(tokens, forKey: key)
    }

    static func load(forKey key: String) -> [String]? {
        UserDefaults.standard.stringArray(forKey: key)
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
        didSet { RouteStorage.save(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.auth.path"

    init() {
        if let tokens = RouteStorage.load(forKey: storageKey) {
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

    private func encode(_ path: [AuthPath]) -> [String] {
        path.map { route in
            switch route {
            case .login: return "login"
            case .validation: return "validation"
            }
        }
    }

    private func decode(_ tokens: [String]) -> [AuthPath] {
        tokens.compactMap { token in
            switch token {
            case "login": return .login
            case "validation": return .validation
            default: return nil
            }
        }
    }
}

final class Tab1Router: Router {
    @Published var path: [Tab1Path] = [] {
        didSet { RouteStorage.save(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.tab1.path"

    init() {
        if let tokens = RouteStorage.load(forKey: storageKey) {
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

    // Persist only steps we can reliably reconstruct.
    private func encode(_ path: [Tab1Path]) -> [String] {
        path.compactMap { route in
            switch route {
            case .screen1: return "screen1"
            case .screen2: return "screen2"
            case .detail: return nil // Not persisted due to unknown identifier
            }
        }
    }

    private func decode(_ tokens: [String]) -> [Tab1Path] {
        tokens.compactMap { token in
            switch token {
            case "screen1": return .screen1
            case "screen2": return .screen2
            default: return nil
            }
        }
    }
}

final class Tab2Router: Router {
    @Published var path: [Tab2Path] = [] {
        didSet { RouteStorage.save(encode(path), forKey: storageKey) }
    }
    private let storageKey = "router.tab2.path"

    init() {
        if let tokens = RouteStorage.load(forKey: storageKey) {
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

    private func encode(_ path: [Tab2Path]) -> [String] {
        path.map { route in
            switch route {
            case .screen1: return "screen1"
            case .screen2: return "screen2"
            case .screen2Detail(let id): return "screen2Detail:\(id)"
            case .screen3: return "screen3"
            }
        }
    }

    private func decode(_ tokens: [String]) -> [Tab2Path] {
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
}

final class Tab3Router: Router {
    @Published var path: [Tab3Path] = [] {
        didSet { RouteStorage.save(encode(path), forKey: pathKey) }
    }
    @Published var modal: Tab3Modal? {
        didSet {
            if let modal = modal {
                RouteStorage.save([encode(modal)], forKey: modalKey)
            } else {
                RouteStorage.clear(forKey: modalKey)
            }
        }
    }
    @Published var fullScreen: Tab3Modal? {
        didSet {
            if let full = fullScreen {
                RouteStorage.save([encode(full)], forKey: fullScreenKey)
            } else {
                RouteStorage.clear(forKey: fullScreenKey)
            }
        }
    }

    private let pathKey = "router.tab3.path"
    private let modalKey = "router.tab3.modal"
    private let fullScreenKey = "router.tab3.fullscreen"

    init() {
        if let tokens = RouteStorage.load(forKey: pathKey) {
            self.path = decode(tokens)
        }
        if let tokens = RouteStorage.load(forKey: modalKey), let first = tokens.first, let m = decodeModal(first) {
            self.modal = m
        }
        if let tokens = RouteStorage.load(forKey: fullScreenKey), let first = tokens.first, let fs = decodeModal(first) {
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

    private func encode(_ path: [Tab3Path]) -> [String] {
        path.map { route in
            switch route {
            case .screen1: return "screen1"
            case .screen2: return "screen2"
            case .screen2Detail(let id): return "screen2Detail:\(id)"
            case .screen2Edit(let id): return "screen2Edit:\(id)"
            case .screen3: return "screen3"
            case .screen4: return "screen4"
            case .screen5: return "screen5"
            case .screen6: return "screen6"
            }
        }
    }

    private func decode(_ tokens: [String]) -> [Tab3Path] {
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

    private func encode(_ modal: Tab3Modal) -> String {
        switch modal {
        case .createItem: return "createItem"
        case .filter: return "filter"
        }
    }

    private func decodeModal(_ token: String) -> Tab3Modal? {
        switch token {
        case "createItem": return .createItem
        case "filter": return .filter
        default: return nil
        }
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
