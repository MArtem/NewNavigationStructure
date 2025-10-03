import SwiftUI

// New router and path types for the fourth tab

enum Tab4Path: Hashable {
    case details(id: Int)
}

final class Tab4Router: Router {
    @Published var path: [Tab4Path] = []

    func push(_ route: Tab4Path) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popTo(_ route: Tab4Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        }
    }

    func navigateTo(_ route: Tab4Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[...index])
        } else {
            path = buildPath(to: route)
        }
    }

    private func buildPath(to route: Tab4Path) -> [Tab4Path] {
        switch route {
        case .details(let id):
            return [.details(id: id)]
        }
    }
}
