import SwiftUI
import SwiftData

@main @MainActor struct KotobaApp: App {
    @State private var controller: AppController?
    @State private var container: ModelContainer?
    @State private var startupError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let controller { RootView(controller: controller) }
                else if let startupError {
                    ContentUnavailableView {
                        Label("Não foi possível abrir o Kotoba", systemImage: "exclamationmark.triangle")
                    } description: { Text(startupError) } actions: {
                        Button("Tentar novamente", action: start)
                    }
                } else { ProgressView("Preparando suas palavras…").task { start() } }
            }
            .tint(KotobaTheme.accent)
        }
    }
    private func start() {
        do {
            let schema = Schema([LearningRecord.self, StudyActivity.self])
            let config = ModelConfiguration("Kotoba", schema: schema, cloudKitDatabase: .none)
            let container = try ModelContainer(for: schema, configurations: [config])
            self.container = container
            controller = try AppController(container: container)
            startupError = nil
        } catch { startupError = error.localizedDescription }
    }
}
