import SwiftUI

final class AppCoordinator: ObservableObject {
    let authRouter = AuthRouter()
    let tab1Router = Tab1Router()
    let tab2Router = Tab2Router()
    let tab3Router = Tab3Router()
    @Published var selectedTab = 0
    @Published var isAuthenticated = false
    let urlManager: UrlManager
    let storeManager: StoreManager
    
    init(storeManager: StoreManager, urlManager: UrlManager = UrlManager()) {
        self.storeManager = storeManager
        self.urlManager = urlManager
    }
    
    func navigateToTabScreen(tab: Int, path: [Tab1Path], selectedTabBinding: Binding<Int>? = nil) {
        tab1Router.path = path
        if let binding = selectedTabBinding { binding.wrappedValue = 0 } else { selectedTab = 0 }
    }

    func navigateToTabScreen(tab: Int, path: [Tab2Path], selectedTabBinding: Binding<Int>? = nil) {
        tab2Router.path = path
        if let binding = selectedTabBinding { binding.wrappedValue = 1 } else { selectedTab = 1 }
    }

    func navigateToTabScreen(tab: Int, path: [Tab3Path], selectedTabBinding: Binding<Int>? = nil) {
        tab3Router.path = path
        if let binding = selectedTabBinding { binding.wrappedValue = 2 } else { selectedTab = 2 }
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
