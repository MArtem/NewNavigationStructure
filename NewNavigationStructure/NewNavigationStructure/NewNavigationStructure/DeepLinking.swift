import SwiftUI

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

final class DeepLinkService: DeepLinkServiceProtocol {
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
            } else { return false }
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
            } else { return false }
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
            } else { return false }
            return true
        default:
            return false
        }
    }
}

final class UrlManager {
    private let deepLinkService: DeepLinkServiceProtocol
    init(deepLinkService: DeepLinkServiceProtocol = DeepLinkService()) { self.deepLinkService = deepLinkService }
    func handleURL(_ url: URL, coordinator: AppCoordinator) -> Bool {
        deepLinkService.processDeepLink(url, coordinator: coordinator)
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
