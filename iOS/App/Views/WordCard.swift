import SwiftUI
import KotobaCore

struct WordCard: View {
    let word: Word
    let controller: AppController
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 58
    var body: some View {
        Surface {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Label("PALAVRA DO MOMENTO", systemImage: "leaf").font(.caption.weight(.semibold)).tracking(1)
                    Spacer()
                    Text("N\(word.jlpt)").font(.caption.weight(.bold)).padding(7).background(KotobaTheme.accent.opacity(0.1), in: Capsule())
                }.foregroundStyle(KotobaTheme.accent)
                VStack(alignment: .leading, spacing: 8) {
                    Text(controller.settings.showKanji ? word.japanese : word.kana)
                        .font(.system(size: wordSize, weight: .medium, design: .serif)).minimumScaleFactor(0.55)
                        .japaneseText()
                    if controller.settings.showKana { Text(word.kana).font(.title3).foregroundStyle(.secondary).japaneseText() }
                    if controller.settings.showRomaji { Text(word.romaji).font(.subheadline).foregroundStyle(.secondary) }
                    if controller.settings.showMeaning { Text(word.meaning).font(.title2.weight(.medium)) }
                    Text(word.partOfSpeech).font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 14) {
                    Button { controller.speak(word) } label: { Label("Ouvir", systemImage: "speaker.wave.2") }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                    Button { controller.favorite(word) } label: {
                        Label(controller.isFavorite(word) ? "Salva" : "Salvar", systemImage: controller.isFavorite(word) ? "bookmark.fill" : "bookmark")
                    }.buttonStyle(.bordered).controlSize(.large)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("NO DIA A DIA").font(.caption.weight(.semibold)).tracking(1).foregroundStyle(.secondary)
                    Text(word.example).font(.title3).japaneseText()
                    if controller.settings.showMeaning { Text(word.exampleMeaning).foregroundStyle(.secondary) }
                    Text(word.note).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}
