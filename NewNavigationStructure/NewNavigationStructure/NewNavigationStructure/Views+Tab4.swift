import SwiftUI

// MARK: - Tab 4 Module and Views
struct Tab4Module {
    let router: Tab4Router
    let coordinator: AppCoordinator
    let model: ScreenModel
    
    func makeView() -> some View {
        Tab4View(router: router, coordinator: coordinator, model: model)
    }
}

struct Tab4View: View {
    @ObservedObject var router: Tab4Router
    let coordinator: AppCoordinator
    let model: ScreenModel
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Tab4RootView(router: router, coordinator: coordinator, model: model)
                .navigationDestination(for: Tab4Path.self) { path in
                    switch path {
                    case .details(let id):
                        Tab4DetailsView(id: id, router: router)
                    }
                }
        }
        .onChange(of: router.path) { _, newPath in
            // Keep empty path as root, no special reset required for now
            if newPath.isEmpty { /* root */ }
        }
    }
}

struct Tab4RootView: View {
    @ObservedObject var router: Tab4Router
    let coordinator: AppCoordinator
    let model: ScreenModel
    @Environment(\.selectedTab) var selectedTab
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Tab 4 - Root")
            Button("Go to Details 1") { router.path = [.details(id: 1)] }
            Button("Go to Details 2") { router.path = [.details(id: 2)] }
            Divider()
            // Cross-tab test buttons
            Button("Switch to Tab 1 - Screen 1") {
                coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1], selectedTabBinding: selectedTab)
            }
            Button("Switch to Tab 2 - Screen 2") {
                coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, .screen2], selectedTabBinding: selectedTab)
            }
            Button("Switch to Tab 3 - Screen 3") {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, .screen2, .screen3], selectedTabBinding: selectedTab)
            }
        }
        .navigationBarBackButtonHidden(true)
        .padding()
    }
}

struct Tab4DetailsView: View {
    let id: Int
    @ObservedObject var router: Tab4Router
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Tab 4 - Details #\(id)")
            Button("Back") { router.pop() }
        }
        .navigationTitle("Details")
    }
}

#Preview {
    let coordinator = AppCoordinator(storeManager: StoreManager(userService: UserDatabaseService(context: PersistenceController.shared.container.viewContext), contentService: ContentDatabaseService(context: PersistenceController.shared.container.viewContext)))
    return Tab4Module(router: coordinator.tab4Router, coordinator: coordinator, model: ScreenModel(networkManager: NetworkManager(), storeManager: coordinator.storeManager)).makeView()
}
