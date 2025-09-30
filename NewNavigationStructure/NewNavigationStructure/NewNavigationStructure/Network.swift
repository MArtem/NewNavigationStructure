import Foundation

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

extension NetworkService {
    func makeRequest<T: Codable>(baseURL: String, endpoint: String, method: String, body: Codable?, session: URLSession) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw NetworkError.decodingFailed(error.localizedDescription) }
    }
    
    func makeVoidRequest(baseURL: String, endpoint: String, method: String, body: Codable?, session: URLSession) async throws {
        guard let url = URL(string: baseURL + endpoint) else { throw NetworkError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.requestFailed("Invalid response: \(response)")
        }
    }
}

final class NetworkManager {
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
        let _: TokenResponse = try await performRequest(AuthNetworkService.self, endpoint: "/api/login", method: "POST", body: ["email": "eve.holt@reqres.in", "password": "cityslicka"])
        return try await performRequest(DataNetworkService.self, endpoint: "/posts/1", method: "GET")
    }
    
    func login() async throws -> Bool {
        let _: TokenResponse = try await performRequest(AuthNetworkService.self, endpoint: "/api/login", method: "POST", body: ["email": "eve.holt@reqres.in", "password": "cityslicka"])
        return true
    }
    
    func logout() async throws { try await performVoidRequest(AuthNetworkService.self, endpoint: "/api/logout", method: "POST") }
    func fetchUserProfile() async throws -> String { try await performRequest(DataNetworkService.self, endpoint: "/users/1", method: "GET") }
    func fetchContent() async throws -> [String] { try await performRequest(ContentNetworkService.self, endpoint: "/content", method: "GET") }
    func deleteContent(id: String) async throws { try await performVoidRequest(ContentNetworkService.self, endpoint: "/content/\(id)", method: "DELETE") }
    func likeContent(id: String) async throws -> Bool { try await performRequest(ContentNetworkService.self, endpoint: "/content/\(id)/like", method: "POST") }
    func fetchCustomers() async throws -> [ApiCustomers] { try await performRequest(ContentNetworkService.self, endpoint: "/users", method: "GET") }
}

final class AuthNetworkService: NetworkService {
    private let baseURL = "https://reqres.in"
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        try await makeRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        try await makeVoidRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
}

final class DataNetworkService: NetworkService {
    private let baseURL = "https://jsonplaceholder.typicode.com"
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        try await makeRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        try await makeVoidRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
}

final class ContentNetworkService: NetworkService {
    private let baseURL = "https://api.github.com"
    private let session: URLSession
    init(session: URLSession = .shared) { self.session = session }
    func performRequest<T: Codable>(_ endpoint: String, method: String, body: Codable? = nil) async throws -> T {
        try await makeRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
    func performVoidRequest(_ endpoint: String, method: String, body: Codable? = nil) async throws {
        try await makeVoidRequest(baseURL: baseURL, endpoint: endpoint, method: method, body: body, session: session)
    }
}
