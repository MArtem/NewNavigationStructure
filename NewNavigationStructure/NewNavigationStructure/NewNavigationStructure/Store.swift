import Foundation
import CoreData

enum AppError: Error {
    case databaseError(String)
    case networkError(String)
}

protocol UserDatabaseServiceProtocol {
    func saveLoginState(_ isLoggedIn: Bool, userId: Int) throws
    func saveUser(_ user: ApiTestUser) throws
    func isUserLoggedIn() throws -> Bool
    func getCurrentUserId() throws -> Int?
    func fetchUser(byId: Int) throws -> ApiTestUser?
    func updateUserProfile(_ profile: String) throws
}

protocol ContentDatabaseServiceProtocol {
    func saveContent(_ content: [String]) throws
    func deleteContent(id: String) throws
    func fetchContent() throws -> [String]
    func saveCustomers(_ customers: [ApiCustomers]) throws
    func fetchCustomers() throws -> [ApiCustomers]
    func deleteCustomer(id: Int) throws
    func updateCustomer(_ customer: ApiCustomers) throws
}

final class StoreManager {
    private let userService: UserDatabaseService
    private let contentService: ContentDatabaseService
    var onLogout: (() -> Void)?
    
    init(userService: UserDatabaseService, contentService: ContentDatabaseService) {
        self.userService = userService
        self.contentService = contentService
    }
    
    private func performTransaction<T>(_ operation: () throws -> Void, entity: T.Type) throws {
        do {
            try operation()
        } catch {
            throw AppError.databaseError(error.localizedDescription)
        }
    }
    
    func saveLoginState(_ isLoggedIn: Bool, userId: Int) throws {
        try performTransaction({ try userService.saveLoginState(isLoggedIn, userId: userId) }, entity: Bool.self)
        if !isLoggedIn { onLogout?() }
    }
    
    func saveUser(_ user: ApiTestUser) throws {
        try performTransaction({ try userService.saveUser(user) }, entity: ApiTestUser.self)
    }
    
    func isUserLoggedIn() throws -> Bool { try userService.isUserLoggedIn() }
    func getCurrentUserId() throws -> Int? { try userService.getCurrentUserId() }
    
    func saveCustomers(_ customers: [ApiCustomers]) throws {
        try performTransaction({ try contentService.saveCustomers(customers) }, entity: [ApiCustomers].self)
    }
    
    func fetchCustomers() throws -> [ApiCustomers] { try contentService.fetchCustomers() }
    func deleteCustomer(id: Int) throws { try performTransaction({ try contentService.deleteCustomer(id: id) }, entity: ApiCustomers.self) }
    func updateCustomer(_ customer: ApiCustomers) throws { try performTransaction({ try contentService.updateCustomer(customer) }, entity: ApiCustomers.self) }
}

final class UserDatabaseService: UserDatabaseServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) { self.context = context }
    
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
            guard let entity = NSEntityDescription.entity(forEntityName: "TestUser", in: context) else { return }
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
            let id = user.value(forKey: "id") as? Int ?? 0
            let userId = user.value(forKey: "userId") as? Int ?? 0
            let title = user.value(forKey: "title") as? String ?? ""
            let body = user.value(forKey: "body") as? String ?? ""
            return ApiTestUser(id: id, userId: userId, title: title, body: body)
        }
        return nil
    }
    
    func updateUserProfile(_ profile: String) throws { }
}

final class ContentDatabaseService: ContentDatabaseServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) { self.context = context }
    
    func saveContent(_ content: [String]) throws { }
    func deleteContent(id: String) throws { }
    func fetchContent() throws -> [String] { ["Content1", "Content2"] }
    
    func saveCustomers(_ customers: [ApiCustomers]) throws {
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Customers")
        let batchDelete = NSBatchDeleteRequest(fetchRequest: deleteRequest)
        try context.execute(batchDelete)
        
        guard let entity = NSEntityDescription.entity(forEntityName: "Customers", in: context) else { return }
        for customer in customers {
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
        return customers.compactMap { customer in
            let id = customer.value(forKey: "id") as? Int ?? 0
            let login = customer.value(forKey: "login") as? String ?? ""
            let html = customer.value(forKey: "html_url") as? String ?? ""
            let avatar = customer.value(forKey: "avatar_url") as? String ?? ""
            return ApiCustomers(id: id, login: login, html_url: html, avatar_url: avatar)
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
