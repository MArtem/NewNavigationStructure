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
    
    func navigateToTabScreen<T>(tab: Int, path: [T], selectedTabBinding: Binding<Int>? = nil) {
        switch tab {
        case 0:
            tab1Router.path = path as! [Tab1Path]
            if let binding = selectedTabBinding { binding.wrappedValue = 0 } else { selectedTab = 0 }
        case 1:
            tab2Router.path = path as! [Tab2Path]
            if let binding = selectedTabBinding { binding.wrappedValue = 1 } else { selectedTab = 1 }
        case 2:
            tab3Router.path = path as! [Tab3Path]
            if let binding = selectedTabBinding { binding.wrappedValue = 2 } else { selectedTab = 2 }
        default:
            break
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
