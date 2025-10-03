//
//  NewNavigationStructureApp.swift
//  NewNavigationStructure
//
//  Created by Artem on 21.02.2025.
//
//Version before AI included
//import UIKit
//Before AI supply  
import SwiftUI
import CoreData

// Moved to Store.swift, Models.swift, and Network.swift (errors, store, models, network services)

//2. Роутеры как протоколы

// Routers and Paths moved to Routers.swift

// AppCoordinator moved to Coordinator.swift


struct MainModule: View {
    let storeManager: StoreManager
    let networkManager: NetworkManager
    let coordinator: AppCoordinator
    
    init(storeManager: StoreManager, networkManager: NetworkManager, coordinator: AppCoordinator) {
        self.storeManager = storeManager
        self.networkManager = networkManager
        self.coordinator = coordinator
    }
    
    var body: some View {
        MainTabView(
            storeManager: storeManager,
            networkManager: networkManager,
            coordinator: coordinator
        )

    }
}


//7. Главная точка входа

struct MainTabView: View {
    let storeManager: StoreManager
    let networkManager: NetworkManager
    @ObservedObject var coordinator: AppCoordinator // Теперь @StateObject внутри MainTabView
    
    init(storeManager: StoreManager, networkManager: NetworkManager, coordinator: AppCoordinator) {
        self.storeManager = storeManager
        self.networkManager = networkManager
        self.coordinator = coordinator
    }
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            Tab1Module(router: coordinator.tab1Router, coordinator: coordinator, model: Tab1ScreenModel(networkManager: networkManager, storeManager: storeManager))
                .makeView()
                .tabItem { Label("Tab 1", systemImage: "1.circle") }
                .tag(0)
            Tab2Module(router: coordinator.tab2Router, coordinator: coordinator, model: Tab2ScreenModel(networkManager: networkManager, storeManager: storeManager))
                .makeView()
                .tabItem { Label("Tab 2", systemImage: "2.circle") }
                .tag(1)
            Tab3Module(router: coordinator.tab3Router, coordinator: coordinator, model: Tab3ScreenModel(networkManager: networkManager, storeManager: storeManager))
                .makeView()
                .tabItem { Label("Tab 3", systemImage: "3.circle") }
                .tag(2)
            Tab4Module(router: coordinator.tab4Router, coordinator: coordinator, model: ScreenModel(networkManager: networkManager, storeManager: storeManager))
                .makeView()
                .tabItem { Label("Tab 4", systemImage: "4.circle") }
                .tag(3)
        }
        .environment(\.selectedTab, $coordinator.selectedTab)

    }
}

// SelectedTab EnvironmentKey moved to Coordinator.swift

// MARK: - Environment Key для передачи callback
struct OnLogoutKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var onLogout: () -> Void {
        get { self[OnLogoutKey.self] }
        set { self[OnLogoutKey.self] = newValue }
    }
}

// Main App
@main
struct NavigationApp: App {
    private let storeManager: StoreManager // Делаем let, так как больше не меняем
    let networkManager: NetworkManager
    @StateObject private var coordinator: AppCoordinator // Объявляем без немедленной инициализации
    
    init() {
        let userDatabaseService = UserDatabaseService(context: PersistenceController.shared.container.viewContext)
        let contentDatabaseService = ContentDatabaseService(context: PersistenceController.shared.container.viewContext)
        let tempStoreManager = StoreManager(userService: userDatabaseService, contentService: contentDatabaseService)
        self.storeManager = tempStoreManager
        self.networkManager = NetworkManager()
        self._coordinator = StateObject(wrappedValue: AppCoordinator(storeManager: tempStoreManager))
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationRootView(
                storeManager: storeManager,
                networkManager: networkManager,
                coordinator: coordinator
            )
            .onAppear {
                storeManager.onLogout = { [weak coordinator] in
                    coordinator?.isAuthenticated = false
                }
                do {
                    coordinator.isAuthenticated = try storeManager.isUserLoggedIn()
                } catch {
                    coordinator.isAuthenticated = false
                }
            }
            .onOpenURL { url in
                if coordinator.urlManager.handleURL(url, coordinator: coordinator) {
                    coordinator.isAuthenticated = true
                }
            }
        }
    }
}

struct NavigationRootView: View {
    let storeManager: StoreManager
    let networkManager: NetworkManager
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        Group {
            if coordinator.isAuthenticated {
                MainModule(
                    storeManager: storeManager,
                    networkManager: networkManager,
                    coordinator: coordinator
                )
            } else {
                AuthModule(
                    router: coordinator.authRouter,
                    storeManager: storeManager,
                    networkManager: networkManager,
                    onAuthSuccess: {
                        do {
                            try storeManager.saveLoginState(true, userId: 1) // Пример userId
                            coordinator.isAuthenticated = true
                        } catch {
                            // Handle error silently
                        }
                    }
                )
            }
        }
        .onAppear {
            do {
                coordinator.isAuthenticated = try storeManager.isUserLoggedIn()
            } catch {
                coordinator.isAuthenticated = false
            }
        }
    }
}

/////////////
// Deep linking moved to DeepLinking.swift




