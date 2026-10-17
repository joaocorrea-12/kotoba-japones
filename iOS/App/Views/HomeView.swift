import SwiftUI

struct HomeView: View {
    let controller: AppController
    @Binding var tab: Int
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ことば / KOTOBA").font(.caption.weight(.bold)).tracking(3).foregroundStyle(KotobaTheme.accent)
                            Text("Um pouco,\ntodos os dias.").font(.largeTitle.weight(.semibold))
                        }
                        Spacer()
                        Label("\(controller.streak)", systemImage: "flame").padding(12)
                            .background(KotobaTheme.warm.opacity(0.1), in: Capsule()).foregroundStyle(KotobaTheme.warm)
                            .accessibilityLabel("Sequência de \(controller.streak) dias estudados")
                    }
                    Text(controller.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline).foregroundStyle(.secondary)
                    if let word = controller.current { WordCard(word: word, controller: controller) }
                    Surface {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label(controller.schedule.pausedAt == nil ? "Seu ritmo" : "Trocas pausadas", systemImage: "clock")
                                Spacer()
                                Button(controller.schedule.pausedAt == nil ? "Pausar" : "Retomar") { controller.togglePause() }
                            }
                            Text("Uma palavra a cada \(intervalTitle(controller.settings.rotationMinutes))")
                                .font(.headline)
                            if let next = controller.schedule.nextChange(after: controller.now) {
                                Text("Próxima troca: \(next.formatted(date: .abbreviated, time: .shortened))").font(.footnote).foregroundStyle(.secondary)
                            }
                            Text("O iOS pode atrasar a atualização visual dos widgets, inclusive nos intervalos de 10 e 20 minutos.")
                                .font(.caption).foregroundStyle(.secondary)
                            Button("Ajustar meu ritmo") { tab = 3 }
                        }
                    }
                    Surface {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack { Text("Seu pequeno progresso").font(.headline); Spacer(); Text("\(controller.studiedToday)/\(controller.settings.dailyGoal)") }
                            ProgressView(value: Double(min(controller.studiedToday, controller.settings.dailyGoal)), total: Double(controller.settings.dailyGoal))
                            Text("\(controller.records.count) palavras vistas · \(controller.records.filter { $0.reviewState.mastered }.count) dominadas")
                                .font(.footnote).foregroundStyle(.secondary)
                            Button { tab = 2 } label: { Label("\(controller.dueRecords.count) revisões para hoje", systemImage: "arrow.clockwise") }
                        }
                    }
                    Text("Uma palavra já é um começo. Continue no seu tempo.")
                        .font(.footnote).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }.padding(20)
            }.background(KotobaTheme.canvas).toolbar(.hidden, for: .navigationBar)
        }
    }
}
