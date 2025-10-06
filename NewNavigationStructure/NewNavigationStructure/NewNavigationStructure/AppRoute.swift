import Foundation

// MARK: - Centralized App Route Model

public enum AppTab: Int, Hashable {
    case tab1 = 0
    case tab2 = 1
    case tab3 = 2
    case tab4 = 3
}

enum AppRoute: Hashable {
    case tab1(Tab1Path)
    case tab2(Tab2Path)
    case tab3(Tab3Path)
    // NOTE: Tab4Path isn't available in this context. Provide a minimal root route.
    case tab4Root
}

// MARK: - URL <-> Route

public struct AppRouteParser {
    public init() {}

    // Example URLs expected:
    // myapp://tab2/screen2detail?id=123
    // myapp://tab3/screen2edit?id=ABC
    // myapp://tab3/screen5
    // myapp://tab2/screen3
    // myapp://tab4/root
    func parse(_ url: URL) -> AppRoute? {
        guard let host = url.host?.lowercased() else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        let first = components.first?.lowercased()
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems

        switch host {
        case "tab1":
            // Only simple routes due to Tab1Path.detail(ApiCustomers) requiring complex model.
            switch first {
            case nil, "screen1":
                return .tab1(.screen1)
            case "screen2":
                return .tab1(.screen2)
            default:
                return nil
            }

        case "tab2":
            switch first {
            case nil, "screen1":
                return .tab2(.screen1)
            case "screen2":
                return .tab2(.screen2)
            case "screen2detail":
                if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                    return .tab2(.screen2Detail(id))
                }
                return nil
            case "screen3":
                return .tab2(.screen3)
            default:
                return nil
            }

        case "tab3":
            switch first {
            case nil, "screen1":
                return .tab3(.screen1)
            case "screen2":
                return .tab3(.screen2)
            case "screen2detail":
                if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                    return .tab3(.screen2Detail(id))
                }
                return nil
            case "screen2edit":
                if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                    return .tab3(.screen2Edit(id))
                }
                return nil
            case "screen3":
                return .tab3(.screen3)
            case "screen4":
                return .tab3(.screen4)
            case "screen5":
                return .tab3(.screen5)
            case "screen6":
                return .tab3(.screen6)
            default:
                return nil
            }

        case "tab4":
            // Minimal handling until Tab4Path is available
            return .tab4Root

        default:
            return nil
        }
    }
}

extension AppRoute {
    func url(scheme: String = "myapp") -> URL? {
        switch self {
        case .tab1(let path):
            let host = "tab1"
            switch path {
            case .screen1:
                return URL(string: "\(scheme)://\(host)/screen1")
            case .screen2:
                return URL(string: "\(scheme)://\(host)/screen2")
            case .detail:
                // Complex model; not supported in a URL builder here.
                return URL(string: "\(scheme)://\(host)/screen2")
            }

        case .tab2(let path):
            let host = "tab2"
            switch path {
            case .screen1:
                return URL(string: "\(scheme)://\(host)/screen1")
            case .screen2:
                return URL(string: "\(scheme)://\(host)/screen2")
            case .screen2Detail(let id):
                return URL(string: "\(scheme)://\(host)/screen2detail?id=\(id)")
            case .screen3:
                return URL(string: "\(scheme)://\(host)/screen3")
            }

        case .tab3(let path):
            let host = "tab3"
            switch path {
            case .screen1:
                return URL(string: "\(scheme)://\(host)/screen1")
            case .screen2:
                return URL(string: "\(scheme)://\(host)/screen2")
            case .screen2Detail(let id):
                return URL(string: "\(scheme)://\(host)/screen2detail?id=\(id)")
            case .screen2Edit(let id):
                return URL(string: "\(scheme)://\(host)/screen2edit?id=\(id)")
            case .screen3:
                return URL(string: "\(scheme)://\(host)/screen3")
            case .screen4:
                return URL(string: "\(scheme)://\(host)/screen4")
            case .screen5:
                return URL(string: "\(scheme)://\(host)/screen5")
            case .screen6:
                return URL(string: "\(scheme)://\(host)/screen6")
            }

        case .tab4Root:
            return URL(string: "\(scheme)://tab4/root")
        }
    }
}
