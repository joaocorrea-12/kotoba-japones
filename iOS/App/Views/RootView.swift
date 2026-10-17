import SwiftUI
import Combine
import KotobaCore

struct RootView: View {
    @Bindable var controller: AppController
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var body: some View {
        TabView(selection: $tab) {
            HomeView(controller: controller, tab: $tab)
                .tabItem { Label("Hoje", systemImage: "sun.max") }.tag(0)
            LibraryView(controller: controller)
                .tabItem { Label("Palavras", systemImage: "books.vertical") }.tag(1)
            ReviewView(controller: controller)
                .tabItem { Label("Revisar", systemImage: "rectangle.on.rectangle") }.tag(2)
            SettingsView(controller: controller)
                .tabItem { Label("Ajustes", systemImage: "slider.horizontal.3") }.tag(3)
        }
        .preferredColorScheme(controller.settings.appearance == .automatic ? nil :
            (controller.settings.appearance == .dark ? .dark : .light))
        .environment(\.locale, Locale(identifier: "pt_BR"))
        .onReceive(timer) { _ in
            if scenePhase == .active {
                let previous = controller.current?.id
                controller.tick()
                if tab == 0, previous != controller.current?.id, let word = controller.current { controller.markSeen(word) }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                controller.activate()
                if tab == 0, let word = controller.current { controller.markSeen(word) }
            }
        }
        .onChange(of: tab) { _, tab in
            if tab == 0, let word = controller.current { controller.markSeen(word) }
        }
        .task {
            controller.activate()
            if let word = controller.current { controller.markSeen(word) }
        }
        .onOpenURL { url in
            guard url.scheme == "kotoba", url.host == "word" else { return }
            controller.open(url.lastPathComponent)
        }
        .sheet(item: $controller.selectedWord) { word in
            NavigationStack {
                ScrollView { WordCard(word: word, controller: controller).padding() }
                    .background(KotobaTheme.canvas)
                    .navigationTitle("Uma palavra, um passo")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { Button("Fechar") { controller.selectedWord = nil } }
            }
        }
        .alert("Uma atenção", isPresented: Binding(get: { controller.errorMessage != nil }, set: { if !$0 { controller.errorMessage = nil } })) {
            Button("Entendi") { controller.errorMessage = nil }
        } message: { Text(controller.errorMessage ?? "") }
    }
}
