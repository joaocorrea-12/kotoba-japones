import SwiftUI
import KotobaCore

struct ReviewView: View {
    let controller: AppController
    @State private var revealed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var next: Word? { controller.dueRecords.first.flatMap { controller.word($0.wordID) } }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let word = next {
                        Text("Tente lembrar antes de virar.").foregroundStyle(.secondary)
                        Surface {
                            VStack(spacing: 24) {
                                Text(controller.settings.showKanji ? word.japanese : word.kana)
                                    .font(.system(size: 60, design: .serif)).japaneseText()
                                Button { controller.speak(word) } label: { Label("Ouvir pronúncia", systemImage: "speaker.wave.2") }
                                if revealed {
                                    Text(word.kana).font(.title2).japaneseText()
                                    if controller.settings.showRomaji { Text(word.romaji).foregroundStyle(.secondary) }
                                    Text(word.meaning).font(.title2.weight(.medium))
                                    Text(word.note).font(.subheadline).foregroundStyle(.secondary)
                                    Text(word.example).japaneseText()
                                    Text(word.exampleMeaning).foregroundStyle(.secondary)
                                } else {
                                    Button("Revelar resposta") {
                                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { revealed = true }
                                    }.buttonStyle(.borderedProminent).controlSize(.large)
                                }
                            }.frame(maxWidth: .infinity)
                        }
                        if revealed {
                            Text("Como foi lembrar?").font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(ReviewRating.allCases, id: \.rawValue) { rating in
                                    Button(rating.title) { controller.rate(word, rating); revealed = false }
                                        .buttonStyle(.bordered).controlSize(.large).frame(minHeight: 44)
                                }
                            }
                        }
                        Text("\(controller.dueRecords.count) cartões aguardando revisão").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ContentUnavailableView("Tudo em dia", systemImage: "checkmark.circle", description: Text("Leia uma palavra na tela Hoje para começar. Volte quando sua próxima revisão chegar."))
                        if let due = controller.records.map(\.due).min() {
                            Text("Próxima revisão: \(due.formatted(date: .abbreviated, time: .shortened))").font(.footnote)
                        }
                    }
                }.padding(20)
            }.background(KotobaTheme.canvas).navigationTitle("Revisar")
                .onChange(of: next?.id) { _, _ in revealed = false }
        }
    }
}
