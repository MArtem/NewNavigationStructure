import SwiftUI

protocol Router: ObservableObject {
    associatedtype Path: Hashable
    var path: [Path] { get set }
    func push(_ route: Path)
    func pop()
    func popTo(_ route: Path)
    func navigateTo(_ route: Path)
}

final class AuthRouter: Router {
    @Published var path: [AuthPath] = []

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
}

final class Tab1Router: Router {
    @Published var path: [Tab1Path] = []

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
}

final class Tab2Router: Router {
    @Published var path: [Tab2Path] = []

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
}

final class Tab3Router: Router {
    @Published var path: [Tab3Path] = []

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
        }
    }
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

enum Tab3Path: Hashable {
    case screen1
    case screen2
    case screen2Detail(String)
    case screen2Edit(String)
    case screen3
    case screen4
}
