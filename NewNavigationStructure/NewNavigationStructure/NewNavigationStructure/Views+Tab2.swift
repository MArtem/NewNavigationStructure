import SwiftUI

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
                        DetailView(id: id, router: router)
                    case .screen3:
                        Screen3Tab2(router: router, coordinator: coordinator, model: model)
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
        .navigationBarBackButtonHidden(router.path.isEmpty)
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
