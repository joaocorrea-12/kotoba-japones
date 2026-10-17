import SwiftUI
import WidgetKit
import KotobaCore

struct WordEntry: TimelineEntry {
    let date: Date
    let word: Word?
    let settings: StudySettings
    let configuration: KotobaWidgetIntent
    var message: String?
}

struct WordProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WordEntry {
        WordEntry(date: Date(), word: (try? Vocabulary.load())?.first,
                  settings: StudySettings(), configuration: KotobaWidgetIntent())
    }
    func snapshot(for configuration: KotobaWidgetIntent, in context: Context) async -> WordEntry {
        entry(at: Date(), configuration: configuration)
    }
    func timeline(for configuration: KotobaWidgetIntent, in context: Context) async -> Timeline<WordEntry> {
        let now = Date()
        do {
            guard let snapshot = try SharedStore.load() else {
                return Timeline(entries: [entry(at: now, configuration: configuration)], policy: .after(now.addingTimeInterval(3600)))
            }
            let words = try Vocabulary.load()
            let lookup = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
            let schedule = snapshot.schedule
            var dates = [now]
            var cursor = now
            // 36 instantes previsíveis por lote. Nunca pede execução contínua.
            // Entradas menores que 5 min são agrupadas, conforme orientação do WidgetKit.
            while dates.count < 36, let next = schedule.nextChange(after: cursor) {
                let date = max(next, cursor.addingTimeInterval(300))
                guard date <= now.addingTimeInterval(7 * 86400) else { break }
                dates.append(date)
                cursor = date
            }
            let entries = dates.map {
                WordEntry(date: $0, word: schedule.wordID(at: $0).flatMap { lookup[$0] }, settings: schedule.settings, configuration: configuration)
            }
            let refresh = dates.last!.addingTimeInterval(300)
            return Timeline(entries: entries, policy: .after(refresh))
        } catch {
            let failed = WordEntry(date: now, word: nil, settings: StudySettings(), configuration: configuration, message: "Abra o Kotoba para conferir o cronograma.")
            return Timeline(entries: [failed], policy: .after(now.addingTimeInterval(1800)))
        }
    }
    private func entry(at date: Date, configuration: KotobaWidgetIntent) -> WordEntry {
        do {
            guard let snapshot = try SharedStore.load() else {
                return WordEntry(date: date, word: nil, settings: StudySettings(), configuration: configuration, message: "Abra o Kotoba para começar.")
            }
            let word = try Vocabulary.load().first { $0.id == snapshot.schedule.wordID(at: date) }
            return WordEntry(date: date, word: word, settings: snapshot.schedule.settings, configuration: configuration)
        } catch {
            return WordEntry(date: date, word: nil, settings: StudySettings(), configuration: configuration, message: "Abra o Kotoba para conferir o cronograma.")
        }
    }
}

struct KotobaWidgetView: View {
    let entry: WordEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    private var showMeaning: Bool { entry.settings.showMeaning && entry.configuration.showTranslation }
    private var forest: Bool { entry.configuration.palette == .forest }
    private var ink: Color { forest ? Color(red: 0.93, green: 0.95, blue: 0.89) : .primary }
    private var background: Color {
        if forest { return Color(red: 0.19, green: 0.31, blue: 0.26) }
        return colorScheme == .dark ? Color(red: 0.12, green: 0.14, blue: 0.13) : Color(red: 0.96, green: 0.95, blue: 0.91)
    }
    var body: some View {
        Group {
            if let word = entry.word {
                content(word).widgetURL(URL(string: "kotoba://word/\(word.id)"))
            } else {
                VStack(alignment: .leading) {
                    Text("ことば").font(.title)
                    Text(entry.message ?? "Abra o Kotoba").font(.caption)
                }.widgetURL(URL(string: "kotoba://home"))
            }
        }
        .containerBackground(for: .widget) { background }
    }

    @ViewBuilder private func content(_ word: Word) -> some View {
        switch family {
        case .accessoryInline:
            Text("\(primary(word))\(showMeaning ? " · " + word.meaning : "")").japaneseText()
        case .accessoryCircular:
            VStack(spacing: 2) {
                Text(primary(word)).font(.headline).minimumScaleFactor(0.4).lineLimit(1).japaneseText()
                Text("N\(word.jlpt)").font(.system(size: 9))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack { Text(primary(word)).font(.headline).japaneseText(); Spacer(); Text("N\(word.jlpt)").font(.caption2) }
                if entry.settings.showKana { Text(word.kana).font(.caption).japaneseText() }
                if showMeaning { Text(word.meaning).font(.caption).lineLimit(1) }
            }
        default:
            VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 10) {
                HStack {
                    Text("KOTOBA").font(.system(size: 10, weight: .semibold)).tracking(2)
                    Spacer()
                    Text("N\(word.jlpt)").font(.caption2)
                }.opacity(0.7)
                Text(primary(word)).font(.system(size: family == .systemSmall ? 34 : 42, weight: .medium, design: .serif))
                    .lineLimit(1).minimumScaleFactor(0.4).japaneseText()
                if entry.settings.showKana { Text(word.kana).font(.subheadline).japaneseText() }
                if entry.settings.showRomaji, family != .systemSmall { Text(word.romaji).font(.caption).opacity(0.7) }
                if showMeaning { Text(word.meaning).font(.subheadline).lineLimit(2) }
                if family == .systemLarge {
                    Divider()
                    Text(word.example).font(.title3).japaneseText()
                    if showMeaning { Text(word.exampleMeaning).font(.subheadline).opacity(0.75) }
                    Spacer(minLength: 0)
                    Text("Um pouco, todos os dias.").font(.caption).opacity(0.6)
                }
            }.foregroundStyle(ink).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    private func primary(_ word: Word) -> String { entry.settings.showKanji ? word.japanese : word.kana }
}

struct KotobaWordWidget: Widget {
    let kind = "KotobaWordWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: KotobaWidgetIntent.self, provider: WordProvider()) { KotobaWidgetView(entry: $0) }
            .configurationDisplayName("Japonês todos os dias")
            .description("Uma palavra, sua leitura e significado. O ritmo vem dos ajustes do Kotoba.")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main struct KotobaWidgets: WidgetBundle { var body: some Widget { KotobaWordWidget() } }
