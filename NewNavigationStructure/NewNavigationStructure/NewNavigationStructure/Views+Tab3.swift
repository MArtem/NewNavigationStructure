import SwiftUI

// MARK: - Модуль Tab 3
struct Tab3Module {
    let router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    func makeView() -> some View {
        Tab3View(router: router, coordinator: coordinator, model: model)
    }
}

struct Tab3View: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Screen1Tab3(router: router, coordinator: coordinator, model: model)
                .navigationDestination(for: Tab3Path.self) { path in
                    switch path {
                        case .screen1:
                            Screen1Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen2:
                            Screen2Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen2Detail(let id):
                            DetailView(id: id, router: router)
                        case .screen2Edit(let id):
                            EditView(id: id, router: router)
                        case .screen3:
                            Screen3Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen4:
                            Screen4Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen5:
                            Screen5Tab3(router: router, coordinator: coordinator, model: model)
                        case .screen6:
                            Screen6Tab3(router: router, coordinator: coordinator, model: model)
                        }
                }
        }
        .onChange(of: router.path) { _, newPath in
            if newPath == [.screen1] { router.path = [] }
        }
        .sheet(item: $router.modal) { modal in
            switch modal {
            case .createItem:
                CreateItemModalView(router: router)
            case .filter:
                // Not used as sheet; use fullScreenCover instead
                EmptyView()
            }
        }
        .fullScreenCover(item: $router.fullScreen) { modal in
            switch modal {
            case .filter:
                FilterFullScreenView(router: router)
            case .createItem:
                // Not used as full screen; presented as sheet
                EmptyView()
            }
        }
    }
}

struct EditView: View {
    let id: String
    let router: Tab3Router
    
    var body: some View {
        VStack {
            Text("Edit for ID: \(id)")
            Button("Back") { router.pop() }
        }
    }
}

struct Screen1Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 1")
            Button("Next") { router.push(.screen2) }
            Button("Back") { router.pop() }
                .disabled(router.path.isEmpty)
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
        }
        .navigationBarBackButtonHidden(router.path.isEmpty)
    }
}

struct Screen2Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 2")
            Button("Next") { router.push(.screen3) }
            Button("Back") { router.pop() }
            Button("To Detail") { router.push(.screen2Detail("Item123")) }
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
        }
    }
}

struct Screen3Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 3")
            Button("Next") { router.push(.screen4) }
            Button("Back") { router.pop() }
            Button("Go to deeplink") {
                if let testUrl = URL(string: "myapp://tab2/screen2detail?id=123") {
                    _ = coordinator.handle(testUrl, selectedTabBinding: nil)
                }
            }
            Button("To Screen 1") { router.navigateTo(.screen1) }
            Button("To Screen 2") { router.navigateTo(.screen2) }
            Button("To Screen 3") { router.navigateTo(.screen3) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
        }
    }
}

struct Screen4Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel
    @Environment(\.selectedTab) var selectedTab
    
    var body: some View {
        VStack {
            Text("Tab 3 - Screen 4")
            Button("Back") { router.pop() }
                .disabled(router.path.isEmpty)
            Button("Back to Screen 1") { router.popTo(.screen1) }
            List {
                Section(header: Text("Tab 1")) {
                    Button("Tab 1 - Screen 1") {
                        coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 1 - Screen 2") {
                        coordinator.navigateToTabScreen(tab: 0, path: [Tab1Path.screen1, Tab1Path.screen2], selectedTabBinding: selectedTab)
                    }
                }
                Section(header: Text("Tab 2")) {
                    Button("Tab 2 - Screen 1") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 2 - Screen 2") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 2 - Screen 3") {
                        coordinator.navigateToTabScreen(tab: 1, path: [Tab2Path.screen1, Tab2Path.screen2, Tab2Path.screen3], selectedTabBinding: selectedTab)
                    }
                }
                Section(header: Text("Tab 3")) {
                    Button("Tab 3 - Screen 1") { router.navigateTo(.screen1) }
                    Button("Tab 3 - Screen 2") { router.navigateTo(.screen2) }
                    Button("Tab 3 - Screen 3") { router.navigateTo(.screen3) }
                    Button("Tab 3 - Screen 4") { router.navigateTo(.screen4) }
                }
                Section(header: Text("Tab 3 — Дополнительные экраны")) {
                    Button("К Screen 5") { goToTab3(.screen5) }
                    Button("К Screen 6") { goToTab3(.screen6) }
                }
                Section(header: Text("Модальные")) {
                    Button("Открыть CreateItem (sheet)") {
                        router.present(.createItem)
                    }
                    Button("Открыть Filter (fullScreen)") {
                        router.presentFullScreen(.filter)
                    }
                    Button("Закрыть модалку") {
                        router.dismissModal()
                        router.dismissFullScreen()
                    }
                }
                Section(header: Text("Tab 4")) {
                    Button("Tab 4 - Root") {
                        coordinator.navigateToTabScreen(tab: 3, path: [] as [Tab4Path], selectedTabBinding: selectedTab)
                    }
                    Button("Tab 4 - Details 42") {
                        coordinator.navigateToTabScreen(tab: 3, path: [.details(id: 42)], selectedTabBinding: selectedTab)
                    }
                }
                Section(header: Text("Deep Links")) {
                    Button("Открыть диплинк: Tab4 → Root") {
                        if let url = URL(string: "myapp://tab4/root") {
                            _ = coordinator.handle(url, selectedTabBinding: selectedTab)
                        }
                    }
                    Button("Открыть диплинк: Tab2 → Screen2Detail(ABC)") {
                        if let url = URL(string: "myapp://tab2/screen2detail?id=ABC") {
                            _ = coordinator.handle(url, selectedTabBinding: selectedTab)
                        }
                    }
                }
            }
        }
    }
    
    private func goToTab3(_ destination: Tab3Path) {
        router.navigateTo(destination)
    }
}

struct Screen5Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel

    var body: some View {
        VStack {
            Text("Tab 3 - Screen 5")
            Button("Next → Screen 6") { router.push(.screen6) }
            Button("Back") { router.pop() }
            Button("To Screen 4") { router.navigateTo(.screen4) }
            Button("To Screen 5") { router.navigateTo(.screen5) }
            Button("To Screen 6") { router.navigateTo(.screen6) }
        }
        .navigationTitle("Screen 5")
    }
}

struct Screen6Tab3: View {
    @ObservedObject var router: Tab3Router
    let coordinator: AppCoordinator
    let model: Tab3ScreenModel

    var body: some View {
        VStack {
            Text("Tab 3 - Screen 6")
            Button("Back") { router.pop() }
            Button("← Go to Screen 5") { router.push(.screen5) }
            Button("To Screen 4") { router.navigateTo(.screen4) }
            Button("To Screen 5") { router.navigateTo(.screen5) }
            Button("To Screen 6") { router.navigateTo(.screen6) }
        }
        .navigationTitle("Screen 6")
    }
}

struct CreateItemModalView: View {
    @ObservedObject var router: Tab3Router
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Создание элемента")) {
                    TextField("Название", text: $name)
                }
                Section {
                    Button("Сохранить и закрыть") {
                        // Здесь могла бы быть логика сохранения
                        router.dismissModal()
                    }
                    Button("Отмена") {
                        router.dismissModal()
                    }
                }
            }
            .navigationTitle("Create Item")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { router.dismissModal() }
                }
            }
        }
    }
}

struct FilterFullScreenView: View {
    @ObservedObject var router: Tab3Router
    @State private var isEnabled: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Toggle("Фильтр активен", isOn: $isEnabled)
                    .padding(.horizontal)
                Button("Применить") {
                    // Применить фильтр
                    router.dismissFullScreen()
                }
                Button("Закрыть") {
                    router.dismissFullScreen()
                }
            }
            .navigationTitle("Filter")
        }
    }
}

