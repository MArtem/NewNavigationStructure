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

//1. Основные сервисы с обработкой ошибок

// MARK: - Ошибки
enum AppError: Error {
    case databaseError(String)
    case networkError(String)
}

// MARK: - Сервисы

protocol UserDatabaseServiceProtocol {
    func saveLoginState(_ isLoggedIn: Bool, userId: Int) throws
    func saveUser(_ user: ApiTestUser) throws
    func isUserLoggedIn() throws -> Bool
    func getCurrentUserId() throws -> Int?
    func fetchUser(byId: Int) throws -> ApiTestUser?
    func updateUserProfile(_ profile: String) throws
}

protocol ContentDatabaseServiceProtocol {
    func saveContent(_ content: [String]) throws // Пример
    func deleteContent(id: String) throws
    func fetchContent() throws -> [String]
}

class StoreManager {
    private let userService: UserDatabaseService
    private let contentService: ContentDatabaseService
    var onLogout: (() -> Void)?
    
    init(userService: UserDatabaseService, contentService: ContentDatabaseService) {
        self.userService = userService
        self.contentService = contentService
    }
    
    func performTransaction<T>(_ operation: () throws -> Void, entity: T.Type) throws {
        do {
            try operation()
        } catch {
            throw AppError.databaseError(error.localizedDescription)
        }
    }
    
    func saveLoginState(_ isLoggedIn: Bool, userId: Int) throws {
        try performTransaction({ try userService.saveLoginState(isLoggedIn, userId: userId) }, entity: Bool.self)
        if !isLoggedIn {
            onLogout?()
        }
    }
    
    func saveUser(_ user: ApiTestUser) throws {
        try performTransaction({ try userService.saveUser(user) }, entity: ApiTestUser.self)
    }
    
    func isUserLoggedIn() throws -> Bool {
        try userService.isUserLoggedIn()
    }
    
    func getCurrentUserId() throws -> Int? {
        try userService.getCurrentUserId()
    }
    
    func saveCustomers(_ customers: [ApiCustomers]) throws {
        try performTransaction({ try contentService.saveCustomers(customers) }, entity: [ApiCustomers].self)
    }
    
    func fetchCustomers() throws -> [ApiCustomers] {
        try contentService.fetchCustomers()
    }
    
    func deleteCustomer(id: Int) throws {
        try performTransaction({ try contentService.deleteCustomer(id: id) }, entity: ApiCustomers.self)
    }
    
    func updateCustomer(_ customer: ApiCustomers) throws {
        try performTransaction({ try contentService.updateCustomer(customer) }, entity: ApiCustomers.self)
    }
}

class UserDatabaseService: UserDatabaseServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func saveLoginState(_ isLoggedIn: Bool, userId: Int) throws {
        let fetchRequest: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %d", userId)
        let sessions = try context.fetch(fetchRequest)
        let session = sessions.first ?? UserSession(context: context)
        session.userId = Int32(userId)
        session.isLoggedIn = isLoggedIn
        try context.save()
    }
    
    func saveUser(_ user: ApiTestUser) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "TestUser")
        fetchRequest.predicate = NSPredicate(format: "id == %d", user.id)
        let existingUsers = try context.fetch(fetchRequest)
        
        if existingUsers.isEmpty {
            let entity = NSEntityDescription.entity(forEntityName: "TestUser", in: context)!
            let userObject = NSManagedObject(entity: entity, insertInto: context)
            userObject.setValue(user.id, forKey: "id")
            userObject.setValue(user.userId, forKey: "userId")
            userObject.setValue(user.title, forKey: "title")
            userObject.setValue(user.body, forKey: "body")
            try context.save()
        }
    }
    
    func isUserLoggedIn() throws -> Bool {
        let fetchRequest: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        let sessions = try context.fetch(fetchRequest)
        return sessions.contains { $0.isLoggedIn }
    }
    
    func getCurrentUserId() throws -> Int? {
        let fetchRequest: NSFetchRequest<UserSession> = UserSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isLoggedIn == true")
        let sessions = try context.fetch(fetchRequest)
        // Преобразуем Int32 в Int
        if let userId = sessions.first?.userId {
            return Int(userId)
        }
        return nil
    }
    
    func fetchUser(byId: Int) throws -> ApiTestUser? {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "TestUser")
        fetchRequest.predicate = NSPredicate(format: "id == %d", byId)
        let users = try context.fetch(fetchRequest)
        if let user = users.first {
            return ApiTestUser(
                id: user.value(forKey: "id") as! Int,
                userId: user.value(forKey: "userId") as! Int,
                title: user.value(forKey: "title") as! String,
                body: user.value(forKey: "body") as! String
            )
        }
        return nil
    }
    
    func updateUserProfile(_ profile: String) throws {
        // Пока не используем
    }
}

class ContentDatabaseService: ContentDatabaseServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func saveContent(_ content: [String]) throws {
        // Пока не используем
    }
    
    func deleteContent(id: String) throws {
        // Пока не используем
    }
    
    func fetchContent() throws -> [String] {
        return ["Content1", "Content2"] // Пока заглушка
    }
    
    func saveCustomers(_ customers: [ApiCustomers]) throws {
        // Удаляем все существующие записи
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Customers")
        let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
        try context.execute(batchDelete)
        
        // Сохраняем новый список
        for customer in customers {
            let entity = NSEntityDescription.entity(forEntityName: "Customers", in: context)!
            let customerObject = NSManagedObject(entity: entity, insertInto: context)
            customerObject.setValue(customer.id, forKey: "id")
            customerObject.setValue(customer.login, forKey: "login")
            customerObject.setValue(customer.html_url, forKey: "html_url")
            customerObject.setValue(customer.avatar_url, forKey: "avatar_url")
        }
        try context.save()
    }
    
    func fetchCustomers() throws -> [ApiCustomers] {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Customers")
        let customers = try context.fetch(fetchRequest)
        return customers.map { customer in
            ApiCustomers(
                id: customer.value(forKey: "id") as! Int,
                login: customer.value(forKey: "login") as! String,
                html_url: customer.value(forKey: "html_url") as! String,
                avatar_url: customer.value(forKey: "avatar_url") as! String
            )
        }
    }
    
    func deleteCustomer(id: Int) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Customers")
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        let customers = try context.fetch(fetchRequest)
        for customer in customers {
            context.delete(customer)
        }
        try context.save()
    }
    
    func updateCustomer(_ customer: ApiCustomers) throws {
        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "Customers")
        fetchRequest.predicate = NSPredicate(format: "id == %d", customer.id)
        let customers = try context.fetch(fetchRequest)
        if let existingCustomer = customers.first {
            existingCustomer.setValue(customer.login, forKey: "login")
            existingCustomer.setValue(customer.html_url, forKey: "html_url")
            existingCustomer.setValue(customer.avatar_url, forKey: "avatar_url")
            try context.save()
        }
    }
}

struct ApiTestUser: Identifiable, Hashable, Codable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

struct ApiCustomers: Identifiable, Codable, Hashable {
    let id: Int
    let login: String
    let html_url: String
    let avatar_url: String
}

struct TokenResponse: Codable {
    let token: String
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed(String)
    case decodingFailed(String)
    case unauthorized
}

protocol NetworkService {
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable?) async throws -> T
    func performVoidRequest(_ endpoint: String, method: String, body: Codable?) async throws
}

class NetworkManager {
    private let session: URLSession
    private let services: [String: NetworkService]
    
    init(session: URLSession = .shared, services: [NetworkService] = [AuthNetworkService(), DataNetworkService(), ContentNetworkService()]) {
        self.session = session
        self.services = Dictionary(uniqueKeysWithValues: services.map { (String(describing: type(of: $0)), $0) })
    }
    
    private func performRequest<T: Codable, S: NetworkService>(_ serviceType: S.Type, endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        guard let service = services[String(describing: serviceType)] as? S else {
            throw NetworkError.requestFailed("Service \(serviceType) not found")
        }
        return try await service.performRequest(endpoint, method: method, body: body)
    }
    
    private func performVoidRequest<S: NetworkService>(_ serviceType: S.Type, endpoint: String, method: String, body: Codable? = nil) async throws {
        guard let service = services[String(describing: serviceType)] as? S else {
            throw NetworkError.requestFailed("Service \(serviceType) not found")
        }
        try await service.performVoidRequest(endpoint, method: method, body: body)
    }
    
    func validateUser() async throws -> ApiTestUser {
        let tokenResponse = try await performRequest(AuthNetworkService.self, endpoint: "/api/login", method: "POST", body: ["email": "eve.holt@reqres.in", "password": "cityslicka"]) as TokenResponse
        return try await performRequest(DataNetworkService.self, endpoint: "/posts/1", method: "GET")
    }
    
    // Остальные методы
    func login() async throws -> Bool {
        let _: TokenResponse = try await performRequest(
            AuthNetworkService.self,
            endpoint: "/api/login",
            method: "POST",
            body: [
                "email": "eve.holt@reqres.in",
                "password": "cityslicka"
            ]
        )
        return true
    }
    
    func logout() async throws {
        try await performVoidRequest(AuthNetworkService.self, endpoint: "/api/logout", method: "POST")
    }
    
    func fetchUserProfile() async throws -> String {
        try await performRequest(DataNetworkService.self, endpoint: "/users/1", method: "GET")
    }
    
    func fetchContent() async throws -> [String] {
        try await performRequest(ContentNetworkService.self, endpoint: "/content", method: "GET")
    }
    
    func deleteContent(id: String) async throws {
        try await performVoidRequest(ContentNetworkService.self, endpoint: "/content/\(id)", method: "DELETE")
    }
    
    func likeContent(id: String) async throws -> Bool {
        try await performRequest(ContentNetworkService.self, endpoint: "/content/\(id)/like", method: "POST")
    }
    
    func fetchCustomers() async throws -> [ApiCustomers] {
        try await performRequest(ContentNetworkService.self, endpoint: "/users", method: "GET")
    }
}

class AuthNetworkService: NetworkService {
    private let baseURL = "https://reqres.in"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
    }
}

class DataNetworkService: NetworkService {
    private let baseURL = "https://jsonplaceholder.typicode.com"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
    }
}
////////
class ContentNetworkService: NetworkService {
    private let baseURL = "https://api.github.com"
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error.localizedDescription)
        }
    }
    
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
    }
}

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

// MARK: - Протокол роутера
protocol Router: ObservableObject {
    associatedtype Path: Hashable
    var path: [Path] { get set }
    func push(_ route: Path)
    func pop()
    func popTo(_ route: Path)
    func navigateTo(_ route: Path)
}

class AuthRouter: AuthRouterProtocol {
    @Published var path: [AuthPath] = []
    
    func push(_ route: AuthPath) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateTo(_ route: AuthPath) {
        path = [route] // Можно модифицировать для поддержки стека
    }
}

protocol AuthRouterProtocol: ObservableObject {
    associatedtype Path
    var path: [Path] { get set }
    func push(_ route: Path)
    func pop()
    func navigateTo(_ route: Path)
}

class Tab1Router: Router {
    @Published var path: [Tab1Path] = []
    
    func push(_ route: Tab1Path) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] { // Если остался только .screen1, сбрасываем
                path = []
            }
        }
    }
    
    func popTo(_ route: Tab1Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[0...index])
        } else if route == .screen1 {
            path = [] // Простой сброс до корня
        }
    }
    
    func navigateTo(_ route: Tab1Path) {
        if route == .screen1 {
            path = [] // Начальный экран, сбрасываем путь
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[0...index]) // Обрезаем до выбранного экрана
        } else {
            //path.append(route) // Добавляем новый экран
            //Альтернатива: можно очистить и построить логический путь
            path = buildPath(to: route)
        }
    }
    
    // Опционально: метод для построения логического пути
    private func buildPath(to route: Tab1Path) -> [Tab1Path] {
        switch route {
        case .screen1:
            return [.screen1]
        case .screen2:
            return [.screen1, .screen2]
        case .detail(let customer):
            return [.screen1, .screen2, .detail(customer)]
        }
    }
}

class Tab2Router: Router {
    @Published var path: [Tab2Path] = []
    
    func push(_ route: Tab2Path) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] { // Если остался только .screen1, сбрасываем
                path = []
            }
        }
    }
    
    func popTo(_ route: Tab2Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[0...index])
        } else if route == .screen1 {
            path = [] // Простой сброс до корня
        }
    }
    
    func navigateTo(_ route: Tab2Path) {
        if route == .screen1 {
            path = [] // Начальный экран, сбрасываем путь
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[0...index]) // Обрезаем до выбранного экрана
        } else {
            //path.append(route) // Добавляем новый экран
            //Альтернатива: можно очистить и построить логический путь
            path = buildPath(to: route)
        }
    }
    
    // Опционально: метод для построения логического пути
    private func buildPath(to route: Tab2Path) -> [Tab2Path] {
        switch route {
        case .screen1:
            return [.screen1]
        case .screen2:
            return [.screen1, .screen2]
        case .screen2Detail(let id):
            return [.screen1, .screen2, .screen2Detail(id)] // Добавляем путь до Detail
        case .screen3:
            return [.screen1, .screen2, .screen3]
        }
    }
}

class Tab3Router: Router {
    @Published var path: [Tab3Path] = []
    
    func push(_ route: Tab3Path) {
        path.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if path == [.screen1] { path = [] }
        }
    }
    
    func popTo(_ route: Tab3Path) {
        if let index = path.firstIndex(of: route) {
            path = Array(path[0...index])
        } else if route == .screen1 {
            path = []
        }
    }

    func navigateTo(_ route: Tab3Path) {
        if route == .screen1 {
            path = [] // Начальный экран, сбрасываем путь
        } else if let index = path.firstIndex(of: route) {
            path = Array(path[0...index]) // Обрезаем до выбранного экрана
        } else {
            //path.append(route) // Добавляем новый экран
            //Альтернатива: можно очистить и построить логический путь
            path = buildPath(to: route)
        }
    }
    
    // Опционально: метод для построения логического пути
    private func buildPath(to route: Tab3Path) -> [Tab3Path] {
            switch route {
            case .screen1:
                return [.screen1]
            case .screen2:
                return [.screen1, .screen2]
            case .screen2Detail(let id):
                return [.screen1, .screen2, .screen2Detail(id)] // Путь до Detail через Screen2
            case .screen2Edit(let id):
                return [.screen1, .screen2, .screen2Detail(id), .screen2Edit(id)] // Полный путь до Edit
            case .screen3:
                return [.screen1, .screen2, .screen3]
            case .screen4:
                return [.screen1, .screen2, .screen3, .screen4]
            }
        }
}

//3. Пути навигации

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
    case screen2Detail(String) // Добавляем подэкран
    case screen3
}

enum Tab3Path: Hashable {
    case screen1
    case screen2
    case screen2Detail(String) // Подэкран с параметром (например, ID)
    case screen2Edit(String)   // Ещё один уровень вложенности
    case screen3
    case screen4
}
//4. Координатор

class AppCoordinator: ObservableObject {
    let authRouter = AuthRouter()
    let tab1Router = Tab1Router()
    let tab2Router = Tab2Router()
    let tab3Router = Tab3Router()
    @Published var selectedTab = 0 // Для управления TabView
    @Published var isAuthenticated = false // Управляем состоянием здесь
    let urlManager: UrlManager
    let storeManager: StoreManager // Добавляем StoreManager
        
    init(storeManager: StoreManager, urlManager: UrlManager = UrlManager()) {
        self.storeManager = storeManager
        self.urlManager = urlManager
    }
    
    func navigateToTabScreen<T>(tab: Int, path: [T], selectedTabBinding: Binding<Int>? = nil) {
        switch tab {
            case 0:
                tab1Router.path = path as! [Tab1Path]
                if let binding = selectedTabBinding {
                    binding.wrappedValue = 0
                } else {
                    selectedTab = 0
                }
            case 1:
                tab2Router.path = path as! [Tab2Path]
                if let binding = selectedTabBinding {
                    binding.wrappedValue = 1
                } else {
                    selectedTab = 1
                }
            case 2:
                tab3Router.path = path as! [Tab3Path]
                if let binding = selectedTabBinding {
                    binding.wrappedValue = 2
                } else {
                    selectedTab = 2
                }
            default:
                break
        }
    }
}
//5. Модули для табов

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

// MARK: - Environment Key для управления активной вкладкой
struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    var selectedTab: Binding<Int> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

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
extension UIApplication {
    var currentURL: URL? {
        if let urlString = CommandLine.arguments.first(where: { $0.hasPrefix("myapp://") }),
           let url = URL(string: urlString) {
            return url
        }
        return nil
    }
}

protocol DeepLinkServiceProtocol {
    func processDeepLink(_ url: URL, coordinator: AppCoordinator) -> Bool
}

class DeepLinkService: DeepLinkServiceProtocol {
    func processDeepLink(_ url: URL, coordinator: AppCoordinator) -> Bool {
        guard url.scheme == "myapp",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else {
            return false
        }
        
        let pathComponents = url.pathComponents.dropFirst().map { String($0) }
        let queryParams = url.queryParameters
        
        switch host {
        case "tab1":
            if pathComponents.contains("screen2") {
                coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen2])
            } else if pathComponents.contains("screen1") {
                coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1])
            } else if pathComponents.contains("detail"),
                      pathComponents.count > 1,
                      let id = Int(pathComponents[1]),
                      let customer = try? coordinator.storeManager.fetchCustomers().first(where: { $0.id == id }) {
                coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen2, .detail(customer)])
            } else {
                return false
            }
            return true
            
        case "tab2":
            if pathComponents.contains("screen2detail"), let id = queryParams["id"] {
                coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2, Tab2Path.screen2Detail(id)])
            } else if pathComponents.contains("screen3") {
                coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2, Tab2Path.screen3])
            } else if pathComponents.contains("screen2") {
                coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2])
            } else if pathComponents.contains("screen1") {
                coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1])
            } else {
                return false
            }
            return true
            
        case "tab3":
            if pathComponents.contains("screen4") {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, Tab3Path.screen2, Tab3Path.screen3, Tab3Path.screen4])
            } else if pathComponents.contains("screen3") {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, Tab3Path.screen2, Tab3Path.screen3])
            } else if pathComponents.contains("screen2edit"), let id = queryParams["id"] {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, Tab3Path.screen2, Tab3Path.screen2Detail(id), Tab3Path.screen2Edit(id)])
            } else if pathComponents.contains("screen2detail"), let id = queryParams["id"] {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, Tab3Path.screen2, Tab3Path.screen2Detail(id)])
            } else if pathComponents.contains("screen2") {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1, Tab3Path.screen2])
            } else if pathComponents.contains("screen1") {
                coordinator.navigateToTabScreen(tab: 2, path: [Tab3Path.screen1])
            } else {
                return false
            }
            return true
            
        default:
            return false
        }
    }
}


class UrlManager {
    private let deepLinkService: DeepLinkServiceProtocol
    
    init(deepLinkService: DeepLinkServiceProtocol = DeepLinkService()) {
        self.deepLinkService = deepLinkService
    }
    
    func handleURL(_ url: URL, coordinator: AppCoordinator) -> Bool {
        let success = deepLinkService.processDeepLink(url, coordinator: coordinator)
        return success
    }
}

extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return [:] }
        return queryItems.reduce(into: [String: String]()) { (dict, item) in
            dict[item.name] = item.value
        }
    }
}

