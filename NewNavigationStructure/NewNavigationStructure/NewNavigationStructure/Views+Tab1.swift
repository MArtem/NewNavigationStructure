import SwiftUI

struct DetailContentView: View {
    let customer: ApiCustomers
    
    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: URL(string: customer.avatar_url)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
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

struct Tab1Module {
    let router: Tab1Router
    let coordinator: AppCoordinator
    let model: Tab1ScreenModel
    func makeView() -> some View { Tab1View(router: router, coordinator: coordinator, model: model) }
}

struct Tab1View: View {
    @ObservedObject var router: Tab1Router
    let coordinator: AppCoordinator
    @ObservedObject var model: Tab1ScreenModel
    
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
            if newPath == [.screen1] { router.path = [] }
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
        .navigationBarBackButtonHidden(router.path.isEmpty)
    }
}

struct Screen2Tab1: View {
    @ObservedObject var router: Tab1Router
    let coordinator: AppCoordinator
    @ObservedObject var model: Tab1ScreenModel
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
                                .frame(width: 40, height: 40)
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
                    .onTapGesture { router.push(.detail(customer)) }
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
