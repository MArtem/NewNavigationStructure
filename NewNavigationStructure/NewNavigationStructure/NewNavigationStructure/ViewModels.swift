import Foundation
import SwiftUI

final class Tab1ScreenModel: ObservableObject {
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
            if NetworkReachability.isConnected() {
                let fetchedCustomers = try await networkManager.fetchCustomers()
                try storeManager.saveCustomers(fetchedCustomers)
                await MainActor.run {
                    customers = fetchedCustomers
                    errorMessage = nil
                }
            } else {
                let dbCustomers = try storeManager.fetchCustomers()
                await MainActor.run {
                    customers = dbCustomers
                    errorMessage = nil
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
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

final class Tab2ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}

final class Tab3ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}

final class ScreenModel: ObservableObject {
    let networkManager: NetworkManager
    let storeManager: StoreManager
    
    init(networkManager: NetworkManager, storeManager: StoreManager) {
        self.networkManager = networkManager
        self.storeManager = storeManager
    }
}
