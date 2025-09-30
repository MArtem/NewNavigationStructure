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

// MARK: - Модели экранов
class Tab1ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    @Published var customers: [ApiCustomers] = []
    @Published var errorMessage: String?
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
    
    func loadCustomers() async {
        do {
            // Проверяем подключение к интернету (заглушка пока)
            if NetworkReachability.isConnected() {
                let fetchedCustomers = try await networkManager.fetchCustomers()
                try storeManager.saveCustomers(fetchedCustomers)
                await MainActor.run {
                    customers = fetchedCustomers
                    errorMessage = nil
                }
            } else {
                // Если нет интернета, берём из БД
                let dbCustomers = try storeManager.fetchCustomers()
                await MainActor.run {
                    customers = dbCustomers
                    errorMessage = nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                // Пробуем загрузить из БД при ошибке
                do {
                    customers = try storeManager.fetchCustomers()
                } catch {
                    errorMessage = "Failed to load from API and DB: \(error.localizedDescription)"
                    customers = []
                }
            }
        }
    }
}

// Временная заглушка для проверки сети
struct NetworkReachability {
    static func isConnected() -> Bool {
        // Реальная проверка позже
        return true
    }
}

class Tab2ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}

class Tab3ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}

class ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}
//2. Роутеры как протоколы

struct AuthModule: View {
    @ObservedObject var router: AuthRouter // Изменяем на @ObservedObject
    let storeManager: StoreManager
    let networkManager: NetworkManager
    let onAuthSuccess: () -> Void
    
    var body: some View {
        NavigationStack(path: $router.path) {
            LoginScreen(router: router, storeManager: storeManager)
                .navigationDestination(for: AuthPath.self) { path in
                    switch path {
                    case .login:
                        LoginScreen(router: router, storeManager: storeManager)
                    case .validation:
                        ValidationScreen(
                            router: router,
                            model: ScreenModel(networkManager: networkManager, storeManager: storeManager),
                            onSuccess: onAuthSuccess
                        )
                    }
                }
        }
    }
}

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

// Routers and Paths moved to Routers.swift

// AppCoordinator moved to Coordinator.swift

// MARK: - Модули для табов

struct DetailContentView: View {
    let customer: ApiCustomers
        
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: customer.avatar_url)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Большой аватар
                    .clipShape(Circle())
                    .padding(.bottom, 20)
            } placeholder: {
                ProgressView()
                    .frame(width: 200, height: 200)
            }
            Text("ID: \(customer.id)")
            Text("Login: \(customer.login)")
            Text("HTML URL: \(customer.html_url)")
            Text("Avatar URL: \(customer.avatar_url)")
            Spacer()
        }
        .navigationTitle("Customer Details")
        .padding()
    }
}

// MARK: - Модуль Tab 1
struct Tab1Module {
    let router: Tab1Router
    let coordinator: AppCoordinator
    let model: Tab1ScreenModel
    
    func makeView() -> some View {
        Tab1View(router: router, coordinator: coordinator, model: model)
    }
}

struct Tab1View: View {
    @ObservedObject var router: Tab1Router
    let coordinator: AppCoordinator
    @ObservedObject var model: Tab1ScreenModel // Обновляем на @ObservedObject
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Screen1Tab1(router: router, coordinator: coordinator, model: model)
                .navigationDestination(for: Tab1Path.self) { path in
                    switch path {
                    case .screen1:
                        Screen1Tab1(router: router, coordinator: coordinator, model: model)
                    case .screen2:
                        Screen2Tab1(router: router, coordinator: coordinator, model: model)
                    case .detail(let customer):
                        DetailContentView(customer: customer)
                    }
                }
        }
        .onChange(of: router.path) { _, newPath in
            if newPath == [.screen1] {
                router.path = [] // Сбрасываем path до [], если остался только .screen1
            }
        }
    }
}

struct Screen1Tab1: View {
    @ObservedObject var router: Tab1Router
    let coordinator: AppCoordinator
    @ObservedObject var model: Tab1ScreenModel
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("Tab 1 - Screen 1")
            if isLoading {
                ProgressView()
            } else {
                Button("Next") { router.push(.screen2) }
                Button("Back") { router.pop() }.disabled(router.path.isEmpty)
                Button("To Screen 1") { router.navigateTo(.screen1) }
                Button("To Screen 2") { router.navigateTo(.screen2) }
                Button("Logout") {
                    Task {
                        isLoading = true
                        do {
                            if let userId = try model.storeManager.getCurrentUserId() {
                                try model.storeManager.saveLoginState(false, userId: userId)
                            }
                        } catch {
                            errorMessage = (error as? AppError)?.localizedDescription
                        }
                        isLoading = false
                    }
                }
                if let errorMessage = errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
        }

        .navigationBarBackButtonHidden(router.path.isEmpty) // Скрываем кнопку "Назад" при path = []
    }
}

struct Screen2Tab1: View {
    @ObservedObject var router: Tab1Router
    let coordinator: AppCoordinator
    @ObservedObject var model: Tab1ScreenModel // Теперь наблюдаем модель
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
            } else if let errorMessage = model.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            } else {
                Text("Tab 1 - Screen 2")
                Button("Back") { router.pop() }
                Button("To Screen 1") { router.navigateTo(.screen1) }
                Button("To Screen 2") { router.navigateTo(.screen2) }
                List(model.customers) { customer in
                    HStack {
                        AsyncImage(url: URL(string: customer.avatar_url)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40) // Маленький аватар
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 40, height: 40)
                        }
                        VStack(alignment: .leading) {
                            Text("ID: \(customer.id)")
                            Text("Login: \(customer.login)")
                            Text("HTML URL: \(customer.html_url)")
                            Text("Avatar URL: \(customer.avatar_url)")
                        }
                    }
                    .onTapGesture {
                        router.push(.detail(customer))
                    }
                }
            }
        }
        .navigationTitle("Customers")
        .onAppear {
            Task {
                isLoading = true
                await model.loadCustomers()
                isLoading = false
            }
        }
    }
}

// MARK: - Модуль Tab 2
struct Tab2Module {
    let router: Tab2Router
    let coordinator: AppCoordinator
    let model: Tab2ScreenModel
    
    func makeView() -> some View {
        Tab2View(router: router, coordinator: coordinator, model: model)
    }
}

struct Tab2View: View {
    @ObservedObject var router: Tab2Router
    let coordinator: AppCoordinator
    let model: Tab2ScreenModel
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Screen1Tab2(router: router, coordinator: coordinator, model: model)
                .navigationDestination(for: Tab2Path.self) { path in
                    switch path {
                        case .screen1:
                            Screen1Tab2(router: router, coordinator: coordinator, model: model)
                        case .screen2:
                            Screen2Tab2(router: router, coordinator: coordinator, model: model)
                        case .screen2Detail(let id):
                            DetailView(id: id, router: router) // Передаём Tab2Router
                        case .screen3:
                            Screen3Tab2(router: router, coordinator: coordinator, model: model)
                        }
                }
        }
        .onChange(of: router.path) { _, newPath in
            if newPath == [.screen1] {
                router.path = [] // Сбрасываем path до [], если остался только .screen1
            }
        }
    }
}

struct Screen1Tab2: View {
    @ObservedObject var router: Tab2Router
    let coordinator: AppCoordinator
    let model: Tab2ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 2 - Screen 1")
            Button("Next") { router.push(.screen2) }
            Button("Back") { router.pop() }
                .disabled(router.path.isEmpty)
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
        }
        .navigationBarBackButtonHidden(router.path.isEmpty) // Скрываем кнопку "Назад" при path = []
    }
}

struct Screen2Tab2: View {
    @ObservedObject var router: Tab2Router
    let coordinator: AppCoordinator
    let model: Tab2ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 2 - Screen 2")
            Button("Next") { router.push(.screen3) }
            Button("Back") { router.pop() }
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
        }
    }
}

struct Screen3Tab2: View {
    @ObservedObject var router: Tab2Router
    let coordinator: AppCoordinator
    let model: Tab2ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 2 - Screen 3")
            Button("Back") { router.pop() }
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
        }
    }
}

// MARK: - Модуль Tab 3
struct Tab3Module {
    let router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    func makeView() -> some View {
        Tab3View(router: router, coordinator: coordinator, model: model)
    }
}

struct Tab3View: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    @State private var isAtRoot = true // Флаг для корневого экрана
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Screen1Tab3(router: router, coordinator: coordinator, model: model)
                .navigationDestination(for: Tab3Path.self) { path in
                    switch path {
                        case .screen1:
                            Screen1Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen2:
                            Screen2Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen2Detail(let id):
                            DetailView(id: id, router: router) // Передаём Tab3Router
                        case .screen2Edit(let id):
                            EditView(id: id, router: router)
                        case .screen3:
                            Screen3Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen4:
                            Screen4Tab3(router: router, coordinator: coordinator, model: model)
                        }
                }
        }
        .onChange(of: router.path) { _, newPath in
            if newPath == [.screen1] {
                router.path = []
            }
        }
    }
}

struct DetailView<R: Router>: View where R.Path: Hashable {
    let id: String
    let router: R
    
    var body: some View {
        VStack {
            Text("Detail for ID: \(id)")
            // Условно добавляем кнопку "Edit" только для Tab3Router
            if router is Tab3Router {
                Button("Edit") {
                    (router as! Tab3Router).push(.screen2Edit(id)) // Приведение типа для Tab3
                }
            }
            Button("Back") { router.pop() }
        }
    }
}

struct EditView: View {
    let id: String
    let router: Tab3Router
    
    var body: some View {
        VStack {
            Text("Edit for ID: \(id)")
            Button("Back") { router.pop() }
        }
    }
}

struct Screen1Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 1")
            Button("Next") { router.push(.screen2) }
            Button("Back") { router.pop() }
                .disabled(router.path.isEmpty)
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
        }
        .navigationBarBackButtonHidden(router.path.isEmpty)
    }
}

struct Screen2Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 2")
                Button("Next") { router.push(.screen3) }
                Button("Back") { router.pop() }
                Button("To Detail") { router.push(.screen2Detail("Item123")) } // Переход на подэкран
                Button("To Screen 1") { router.navigateTo(.screen1) }
                Button("To Screen 2") { router.navigateTo(.screen2) }
                Button("To Screen 3") { router.navigateTo(.screen3) }
                Button("To Screen 4") { router.navigateTo(.screen4) }
        }
    }
}

struct Screen3Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 3")
            Button("Next") { router.push(.screen4) }
            Button("Back") { router.pop() }
            Button("Go to deeplink") {
                //myapp://tab2/screen2detail?id=123
                //myapp://tab3/screen4
                if let testUrl = URL(string: "myapp://tab2/screen2detail?id=123") {
                    if coordinator.urlManager.handleURL(testUrl, coordinator: coordinator) {
                    }
                }
            }
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
        }
    }
}

struct Screen4Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    @Environment(\.selectedTab) var selectedTab // Получаем управление вкладкой
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 4")
            Button("Back") { router.pop() }
                .disabled(router.path.isEmpty)
            Button("Back to Screen 1") { router.popTo(.screen1) } // Пункт 3
            List {
                Section(header: Text("Tab 1")) {
                    Button("Tab 1 - Screen 1") {
                        coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 1 - Screen 2") {
                        coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1, Tab1Path.screen2], selectedTabBinding: selectedTab)
                    }
                }
                Section(header: Text("Tab 2")) {
                    Button("Tab 2 - Screen 1") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 2 - Screen 2") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 2 - Screen 3") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2, Tab2Path.screen3], selectedTabBinding: selectedTab)
                    }
                }
                Section(header: Text("Tab 3")) {
                    Button("Tab 3 - Screen 1") { router.navigateTo(.screen1) }
                    Button("Tab 3 - Screen 2") { router.navigateTo(.screen2) }
                    Button("Tab 3 - Screen 3") { router.navigateTo(.screen3) }
                    Button("Tab 3 - Screen 4") { router.navigateTo(.screen4) }
                }
            }
        }
    }
}
//6. Экраны авторизации

struct LoginScreen: View {
    @ObservedObject var router: AuthRouter
    let storeManager: StoreManager
    
    var body: some View {
        VStack {
            Text("Login Screen")
            Button("Login") {
                router.push(.validation)
            }
        }
    }
}

struct ValidationScreen: View {
    @ObservedObject var router: AuthRouter
    let model: ScreenModel
    let onSuccess: () -> Void
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Text("Validation Screen")
            if isLoading {
                ProgressView()
            } else {
                Button("OK") {
                    Task {
                        isLoading = true
                        do {
                            //let user = try await model.networkManager.validateUser()
                            let user = ApiTestUser(id: 777, userId: 555, title: "test", body: "rrr")
                            try model.storeManager.saveUser(user)
                            try model.storeManager.saveLoginState(true, userId: user.userId) // Сохраняем сессию с userId
                            router.path = []
                            onSuccess()
                        } catch {
                            errorMessage = (error as? AppError)?.localizedDescription ?? error.localizedDescription
                        }
                        isLoading = false
                    }
                }
            }
            if let errorMessage = errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
        }
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
    let persistenceController = PersistenceController.shared
    private let storeManager: StoreManager // Делаем let, так как больше не меняем
    let networkManager: NetworkManager
    @StateObject private var coordinator: AppCoordinator // Объявляем без немедленной инициализации
    
    init() {
        let context = persistenceController.container.viewContext
        let userDatabaseService = UserDatabaseService(context: context)
        let contentDatabaseService = ContentDatabaseService(context: context)
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

// MARK: - Core Data Persistence
struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NavigationAppModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

/////////////
// Deep linking moved to DeepLinking.swift
