import SwiftUI
import KotobaCore
import UIKit

struct SettingsView: View {
    let controller: AppController
    @State private var draft = StudySettings()
    @State private var rotationChoice = 60
    @State private var customAmount = 90
    @State private var customUnit = 1
    @State private var saving = false
    @State private var saved = false
    private let weekdayNames = ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"]
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Trocar palavra", selection: $rotationChoice) {
                        ForEach(StudySettings.presets, id: \.self) { Text("A cada \(intervalTitle($0))").tag($0) }
                        Text("Personalizado").tag(0)
                    }
                    if rotationChoice == 0 {
                        HStack {
                            TextField("Quantidade", value: $customAmount, format: .number).keyboardType(.numberPad)
                                .accessibilityLabel("Quantidade do intervalo personalizado")
                            Picker("Unidade", selection: $customUnit) { Text("Minutos").tag(1); Text("Horas").tag(60) }.labelsHidden()
                        }
                        Text("De 1 minuto a 7 dias. No widget, intervalos menores que 5 minutos são agrupados em oportunidades de atualização.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Toggle("Ordem aleatória", isOn: $draft.randomOrder)
                    Picker("Nível de estudo", selection: $draft.level) {
                        ForEach([5, 4, 3, 2, 1], id: \.self) { Text("JLPT N\($0)").tag($0) }
                    }
                    Text("A base inicial é N5. Níveis posteriores também incluem a base anterior; o conteúdo avançado será acrescentado em outra fase.").font(.caption)
                    Button(controller.schedule.pausedAt == nil ? "Pausar trocas e avisos" : "Retomar trocas e avisos") { controller.togglePause() }
                } header: { Text("Seu ritmo") } footer: {
                    Text("O intervalo é uma opção de estudo. Atualizações visíveis dos widgets, inclusive a cada 10 ou 20 minutos, podem atrasar por decisão do iOS.")
                }
                Section("Dias de estudo") {
                    ForEach(1...7, id: \.self) { day in
                        Toggle(weekdayNames[day - 1], isOn: Binding(get: { draft.weekdays.contains(day) }, set: {
                            if $0 { draft.weekdays.insert(day) } else { draft.weekdays.remove(day) }
                        }))
                    }
                    Text("As trocas ficam congeladas nos dias desmarcados. A sequência de dias conta dias corridos com atividade real.").font(.caption)
                }
                Section {
                    Toggle("Receber notificações", isOn: $draft.notificationsEnabled)
                    if draft.notificationsEnabled {
                        Stepper(value: $draft.notificationMinutes, in: 1...10_080, step: 1) {
                            Text("Avisar a cada \(intervalTitle(draft.notificationMinutes))")
                        }
                        Picker("Intervalos comuns de aviso", selection: $draft.notificationMinutes) {
                            ForEach(Array(Set(StudySettings.presets + [draft.notificationMinutes])).sorted(), id: \.self) {
                                Text(intervalTitle($0)).tag($0)
                            }
                        }
                        Toggle("Horário de silêncio", isOn: $draft.quietEnabled)
                        if draft.quietEnabled {
                            DatePicker("Silêncio a partir de", selection: timeBinding(\.quietStart), displayedComponents: .hourAndMinute)
                            DatePicker("Voltar a avisar às", selection: timeBinding(\.quietEnd), displayedComponents: .hourAndMinute)
                        }
                    }
                    if controller.notificationReport.permissionDenied {
                        Button("Permitir nos Ajustes do iPhone") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                    if let last = controller.notificationReport.lastDate {
                        Text("\(controller.notificationReport.count) avisos na fila, até \(last.formatted(date: .abbreviated, time: .shortened)).").font(.caption)
                    }
                } header: { Text("Notificações") } footer: {
                    Text("Os avisos são independentes das trocas. A fila tem até 60 avisos para os próximos 30 dias e é renovada ao abrir o app ou salvar ajustes. Depois de esgotada, abra o Kotoba para continuar recebendo avisos. Foco e ajustes do sistema podem silenciá-los.")
                }
                Section("Leitura e aparência") {
                    Toggle("Exibir kanji", isOn: $draft.showKanji)
                    Toggle("Exibir leitura em hiragana", isOn: $draft.showKana)
                    Toggle("Exibir romaji", isOn: $draft.showRomaji)
                    Toggle("Exibir traduções", isOn: $draft.showMeaning)
                    Text("Na revisão, a resposta aparece somente ao tocar em Revelar, mesmo com traduções ocultas nas outras telas.").font(.caption)
                    Picker("Tema do app", selection: $draft.appearance) {
                        ForEach(Appearance.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Text("Para personalizar o widget, mantenha-o pressionado e escolha Editar Widget. A aparência segue o sistema e o tema escolhido para cada widget.").font(.caption)
                }
                Section("Pronúncia e meta") {
                    Slider(value: $draft.speechRate, in: 0.2...0.6, step: 0.05) { Text("Velocidade da pronúncia") }
                    Button("Experimentar pronúncia") { if let word = controller.current { controller.speakPreview(word, rate: draft.speechRate) } }
                    Stepper("Meta: \(draft.dailyGoal) palavras por dia", value: $draft.dailyGoal, in: 1...100)
                }
                Section("Acessibilidade") {
                    Text("Compatível com texto ampliado, VoiceOver e a preferência Reduzir Movimento do iPhone. As palavras e frases usam identificação de idioma japonês.")
                    Button("Abrir Ajustes do iPhone") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                }
                Section {
                    Text("Gratuito. Sem conta, anúncios ou assinatura. Seus dados ficam neste iPhone e no App Group local. iCloud não está ativado nesta versão.")
                    Text("Conteúdo original · 121 palavras · base introdutória N5 estimada. Exportação, curso completo e escrita estão previstos para fases futuras.")
                    Text("Fuso do cronograma: \(draft.timeZoneID). Atualizado ao abrir o app em outra região.").font(.caption)
                } header: { Text("Sobre o Kotoba") }
                Section {
                    Button {
                        Task {
                            saving = true
                            draft.rotationMinutes = rotationChoice == 0 ? safeCustomMinutes : rotationChoice
                            let didSave = await controller.update(draft)
                            saved = didSave && controller.errorMessage == nil
                            draft = controller.settings
                            saving = false
                        }
                    } label: {
                        HStack { Spacer(); if saving { ProgressView() }; Text("Salvar ajustes"); Spacer() }
                    }.disabled(saving)
                }
            }.navigationTitle("No seu ritmo")
                .onAppear {
                    draft = controller.settings
                    rotationChoice = StudySettings.presets.contains(draft.rotationMinutes) ? draft.rotationMinutes : 0
                    customAmount = draft.rotationMinutes
                    customUnit = 1
                }
                .alert("Ajustes salvos", isPresented: $saved) { Button("Continuar", role: .cancel) {} } message: {
                    Text("O cronograma foi compartilhado com os widgets. A atualização visual depende do iOS.")
                }
        }
    }
    private var safeCustomMinutes: Int {
        guard (1...10_080).contains(customAmount), customAmount <= 10_080 / customUnit else { return 0 }
        return customAmount * customUnit
    }
    private func timeBinding(_ path: WritableKeyPath<StudySettings, Int>) -> Binding<Date> {
        Binding(get: {
            let minute = draft[keyPath: path]
            return draft.calendar.date(from: DateComponents(year: 2026, month: 1, day: 15, hour: minute / 60, minute: minute % 60)) ?? Date()
        }, set: {
            let parts = draft.calendar.dateComponents([.hour, .minute], from: $0)
            draft[keyPath: path] = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        })
    }
}
