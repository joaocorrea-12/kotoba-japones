import SwiftUI
import KotobaCore

struct LibraryView: View {
    let controller: AppController
    @State private var query = ""
    @State private var filter = 0
    private var items: [Word] {
        let source: [Word]
        switch filter {
        case 1: source = controller.words.filter { controller.isFavorite($0) }
        case 2:
            source = controller.records.sorted { $0.lastSeen > $1.lastSeen }.compactMap { controller.word($0.wordID) }
        case 3:
            var seen: Set<String> = []
            source = controller.schedule.recentIDs(at: controller.now).filter { seen.insert($0).inserted }.compactMap(controller.word)
        default: source = controller.words
        }
        guard !query.isEmpty else { return source }
        return source.filter { [$0.japanese, $0.kana, $0.romaji, $0.meaning].contains { $0.localizedStandardContains(query) } }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Mostrar", selection: $filter) {
                        Text("Todas").tag(0); Text("Salvas").tag(1); Text("Vistas").tag(2); Text("Anteriores").tag(3)
                    }.pickerStyle(.segmented)
                }
                if filter == 3 {
                    Text("Palavras recentes do cronograma. Elas só contam como estudadas quando você abre o cartão no app.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(items) { word in
                    Button { controller.open(word.id) } label: {
                        HStack(spacing: 16) {
                            Text(controller.settings.showKanji ? word.japanese : word.kana).font(.title2).foregroundStyle(.primary).japaneseText()
                            VStack(alignment: .leading, spacing: 4) {
                                if controller.settings.showKana { Text(word.kana).foregroundStyle(.secondary).japaneseText() }
                                if controller.settings.showMeaning { Text(word.meaning).foregroundStyle(.primary) }
                            }
                            Spacer()
                            if controller.isFavorite(word) { Image(systemName: "bookmark.fill").foregroundStyle(KotobaTheme.accent) }
                        }.padding(.vertical, 6)
                    }
                }
                if items.isEmpty { Text("Nenhuma palavra por aqui ainda.").foregroundStyle(.secondary) }
            }.navigationTitle("Suas palavras").searchable(text: $query, prompt: "Japonês, leitura ou português")
        }
    }
}
