import Foundation

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
