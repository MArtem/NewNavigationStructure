//
//  NewNavigationStructureTests.swift
//  NewNavigationStructureTests
//
//  Created by Artem on 21.02.2025.
//

import Testing
import Foundation
@testable import NewNavigationStructure

@Suite("Navigation Routers Persistence & Migration")
struct NewNavigationStructureTests {

    // Storage keys mirrored from the app for test isolation
    private let authKey = "router.auth.path"
    private let tab1Key = "router.tab1.path"
    private let tab2Key = "router.tab2.path"
    private let tab3PathKey = "router.tab3.path"
    private let tab3ModalKey = "router.tab3.modal"
    private let tab3FullKey = "router.tab3.fullscreen"

    private func clearAllRouterKeys() {
        let defaults = UserDefaults.standard
        [authKey, tab1Key, tab2Key, tab3PathKey, tab3ModalKey, tab3FullKey].forEach { defaults.removeObject(forKey: $0) }
    }

    @Test("AuthRouter persists and posts logout notification")
    func authRouterPersistsAndLogoutPostsNotification() async throws {
        clearAllRouterKeys()

        var didReceiveLogout = false
        let token = NotificationCenter.default.addObserver(forName: .routerDidLogout, object: nil, queue: .main) { _ in
            didReceiveLogout = true
        }
        defer { NotificationCenter.default.removeObserver(token) }

        // Persist a route
        let router = AuthRouter()
        router.navigateTo(.validation)

        // New instance should restore the same path
        let router2 = AuthRouter()
        #expect(router2.path == [.validation])

        // Trigger logout and verify notification + clear
        await MainActor.run { router.popTo(.login) }
        #expect(router.path.isEmpty)
        #expect(didReceiveLogout == true)
    }

    @Test("Tab2Router migrates legacy strings and reloads Codable")
    func tab2RouterLegacyMigrationAndCodableReload() async throws {
        clearAllRouterKeys()

        // Write legacy string tokens directly
        UserDefaults.standard.set(["screen1", "screen2", "screen2Detail:42", "screen3"], forKey: tab2Key)

        let router = Tab2Router()
        #expect(router.path == [.screen1, .screen2, .screen2Detail("42"), .screen3])

        // A second instance should load from Codable (written during migration)
        let router2 = Tab2Router()
        #expect(router2.path == router.path)
    }

    @Test("Tab3Router migrates legacy path and modal/fullScreen, responds to logout")
    func tab3RouterLegacyModalAndPathMigrationAndLogout() async throws {
        clearAllRouterKeys()

        // Legacy path & modals
        UserDefaults.standard.set(["screen1", "screen2", "screen2Detail:abc"], forKey: tab3PathKey)
        UserDefaults.standard.set(["createItem"], forKey: tab3ModalKey)
        UserDefaults.standard.set(["filter"], forKey: tab3FullKey)

        let router = Tab3Router()
        #expect(router.path == [.screen1, .screen2, .screen2Detail("abc")])
        #expect(router.modal == .createItem)
        #expect(router.fullScreen == .filter)

        // Ensure Codable re-load works
        let router2 = Tab3Router()
        #expect(router2.path == router.path)
        #expect(router2.modal == .createItem)
        #expect(router2.fullScreen == .filter)

        // Logout clears everything
        await MainActor.run { NotificationCenter.default.post(name: .routerDidLogout, object: nil) }
        #expect(router.path.isEmpty)
        #expect(router.modal == nil)
        #expect(router.fullScreen == nil)
    }

    @Test("Tab1Router basic persistence and logout")
    func tab1RouterBasicPersistenceAndLogout() async throws {
        clearAllRouterKeys()

        let router = Tab1Router()
        router.navigateTo(.screen2) // builds [.screen1, .screen2]

        let router2 = Tab1Router()
        #expect(router2.path == [.screen1, .screen2])

        // Logout clears
        await MainActor.run { NotificationCenter.default.post(name: .routerDidLogout, object: nil) }
        #expect(router.path.isEmpty)
    }
}
