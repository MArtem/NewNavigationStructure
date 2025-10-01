import SwiftUI

struct AuthModule: View {
    @ObservedObject var router: AuthRouter
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

struct LoginScreen: View {
    @ObservedObject var router: AuthRouter
    let storeManager: StoreManager
    
    var body: some View {
        VStack {
            Text("Login Screen")
            Button("Login") { router.push(.validation) }
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
                            // let user = try await model.networkManager.validateUser()
                            let user = ApiTestUser(id: 777, userId: 555, title: "test", body: "rrr")
                            try model.storeManager.saveUser(user)
                            try model.storeManager.saveLoginState(true, userId: user.userId)
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
