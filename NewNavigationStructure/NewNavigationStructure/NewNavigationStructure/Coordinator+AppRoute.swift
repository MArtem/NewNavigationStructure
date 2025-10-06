import SwiftUI

// This extension assumes you have an AppCoordinator with access to routers and selectedTab binding.
// Adjust method bodies to match your actual coordinator API.

protocol AppRouting {
    func navigate(to route: AppRoute, selectedTabBinding: Binding<Int>?)
}

extension AppCoordinator: AppRouting {
    public func navigate(to route: AppRoute, selectedTabBinding: Binding<Int>?) {
        switch route {
        case .tab1(let path):
            navigateToTabScreen(tab: 0, path: [path], selectedTabBinding: selectedTabBinding)

        case .tab2(let path):
            navigateToTabScreen(tab: 1, path: [path], selectedTabBinding: selectedTabBinding)

        case .tab3(let path):
            navigateToTabScreen(tab: 2, path: [path], selectedTabBinding: selectedTabBinding)

        case .tab4Root:
            // Minimal handling until Tab4Path is wired here
            navigateToTabScreen(tab: 3, path: [] as [Tab4Path], selectedTabBinding: selectedTabBinding)
        }
    }
}

extension AppCoordinator {
    @discardableResult
    func handle(_ url: URL, selectedTabBinding: Binding<Int>?) -> Bool {
        let parser = AppRouteParser()
        guard let route = parser.parse(url) else { return false }
        navigate(to: route, selectedTabBinding: selectedTabBinding)
        return true
    }
}
