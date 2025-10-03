//
//import SwiftUI

import SwiftUI

// MARK: - Dynamic, type-erased tab routing support

// Routers that own a NavigationStack path should conform to this.
protocol TabRouter: ObservableObject {
    associatedtype Path: Hashable
    var path: [Path] { get set }
}

// Make existing routers conform to TabRouter so we can type-erase them.
extension Tab1Router: TabRouter { typealias Path = Tab1Path }
extension Tab2Router: TabRouter { typealias Path = Tab2Path }
extension Tab3Router: TabRouter { typealias Path = Tab3Path }
extension Tab4Router: TabRouter { typealias Path = Tab4Path }

// Type-erased wrapper that lets us set a path without knowing its concrete type.
final class AnyTabRouterBox: ObservableObject {
    private let _setPath: (Any) -> Bool

    init<R: TabRouter>(_ router: R) {
        self._setPath = { any in
            if let p = any as? [R.Path] {
                router.path = p
                return true
            }
            return false
        }
    }

    @discardableResult
    func setPathIfCompatible(_ anyPath: Any) -> Bool {
        _setPath(anyPath)
    }
}

final class AppCoordinator: ObservableObject {
    let authRouter = AuthRouter()
    let tab1Router = Tab1Router()
    let tab2Router = Tab2Router()
    let tab3Router = Tab3Router()
    let tab4Router = Tab4Router()
    // Unified, extensible storage for tab routers
    private let tabRouters: [AnyTabRouterBox]
    @Published var selectedTab = 0
    @Published var isAuthenticated = false
    let urlManager: UrlManager
    let storeManager: StoreManager

    init(storeManager: StoreManager, urlManager: UrlManager = UrlManager()) {
        self.storeManager = storeManager
        self.urlManager = urlManager
        // Register tab routers here. To add a new tab, append a new router box.
        self.tabRouters = [
            AnyTabRouterBox(tab1Router),
            AnyTabRouterBox(tab2Router),
            AnyTabRouterBox(tab3Router),
            AnyTabRouterBox(tab4Router)
        ]
    }

    func navigateToTabScreen(tab: Int, path: [Tab1Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 0, path: path, selectedTabBinding: selectedTabBinding)
    }

    func navigateToTabScreen(tab: Int, path: [Tab2Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 1, path: path, selectedTabBinding: selectedTabBinding)
    }

    func navigateToTabScreen(tab: Int, path: [Tab3Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 2, path: path, selectedTabBinding: selectedTabBinding)
    }
    
    func navigateToTabScreen(tab: Int, path: [Tab4Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 3, path: path, selectedTabBinding: selectedTabBinding)
    }

    // Convenience, strongly-typed helpers to avoid ambiguity with empty array literals
    func navigateToTab1(path: [Tab1Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 0, path: path, selectedTabBinding: selectedTabBinding)
    }

    func navigateToTab2(path: [Tab2Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 1, path: path, selectedTabBinding: selectedTabBinding)
    }

    func navigateToTab3(path: [Tab3Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 2, path: path, selectedTabBinding: selectedTabBinding)
    }

    func navigateToTab4(path: [Tab4Path], selectedTabBinding: Binding<Int>? = nil) {
        navigateToTabScreenErased(tab: 3, path: path, selectedTabBinding: selectedTabBinding)
    }

    // Generic, type-erased navigation entry point. Works for any tab whose router is registered above.
    private func navigateToTabScreenErased<T: Hashable>(tab: Int, path: [T], selectedTabBinding: Binding<Int>? = nil) {
        guard tabRouters.indices.contains(tab) else { return }
        _ = tabRouters[tab].setPathIfCompatible(path)
        if let binding = selectedTabBinding {
            binding.wrappedValue = tab
        } else {
            selectedTab = tab
        }
    }
}

struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

