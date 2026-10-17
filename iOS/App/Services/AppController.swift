import Foundation
import SwiftUI
import SwiftData
import WidgetKit
import KotobaCore

@MainActor @Observable final class AppController {
    let words: [Word]
    let context: ModelContext
    private(set) var schedule: WordSchedule
    private(set) var records: [LearningRecord] = []
    private(set) var activities: [StudyActivity] = []
    var now = Date()
    var errorMessage: String?
    var notificationReport = NotificationReport()
    var selectedWord: Word?
    private let speech = SpeechService()
    private let notifications = NotificationService()
    private var rescheduleTask: Task<Void, Never>?

    init(container: ModelContainer) throws {
        context = ModelContext(container)
        context.autosaveEnabled = false
        words = try Vocabulary.load()
        if let snapshot = try SharedStore.load() {
            let ids = Set(words.map(\.id))
            guard snapshot.schedule.orderedIDs.allSatisfy(ids.contains) else { throw SettingsError.invalidSchedule }
            schedule = snapshot.schedule
        } else {
            let settings = StudySettings()
            schedule = WordSchedule(anchor: Date(), orderedIDs: words.map(\.id), settings: settings,
                                    seed: UInt64.random(in: 1...UInt64.max))
            try SharedStore.save(schedule)
        }
        try reloadRecords()
        notifications.onOpenWord = { [weak self] id in self?.open(id) }
    }

    var settings: StudySettings { schedule.settings }
    var current: Word? { word(schedule.wordID(at: now)) }
    var dueRecords: [LearningRecord] { records.filter { $0.due <= now }.sorted { $0.due < $1.due } }
    var studiedToday: Int {
        Set(activities.filter { settings.calendar.isDate($0.date, inSameDayAs: now) }.map(\.wordID)).count
    }
    var streak: Int {
        let calendar = settings.calendar
        let days = Set(activities.map { calendar.startOfDay(for: $0.date) })
        var cursor = calendar.startOfDay(for: now)
        if !days.contains(cursor) { cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
        var total = 0
        while days.contains(cursor) {
            total += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return total
    }

    func word(_ id: String?) -> Word? { words.first { $0.id == id } }
    func record(_ id: String) -> LearningRecord? { records.first { $0.wordID == id } }
    func isFavorite(_ word: Word) -> Bool { record(word.id)?.favorite ?? false }
    private func reloadRecords() throws {
        records = try context.fetch(FetchDescriptor<LearningRecord>())
        activities = try context.fetch(FetchDescriptor<StudyActivity>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
    }
    private func ensureRecord(_ word: Word) -> LearningRecord {
        if let value = record(word.id) { return value }
        let value = LearningRecord(wordID: word.id, now: now)
        context.insert(value)
        return value
    }
    private func saveProgress() {
        do { try context.save(); try reloadRecords() }
        catch { context.rollback(); errorMessage = "Não foi possível salvar o progresso: \(error.localizedDescription)" }
    }
    func markSeen(_ word: Word) {
        let value = ensureRecord(word)
        value.lastSeen = now
        if !activities.contains(where: { $0.wordID == word.id && settings.calendar.isDate($0.date, inSameDayAs: now) }) {
            context.insert(StudyActivity(wordID: word.id, date: now, kind: "leitura"))
        }
        saveProgress()
    }
    func favorite(_ word: Word) {
        let value = ensureRecord(word)
        value.favorite.toggle()
        saveProgress()
    }
    func rate(_ word: Word, _ rating: ReviewRating) {
        let value = ensureRecord(word)
        let wasMastered = value.reviewState.mastered
        var state = value.reviewState
        state.rate(rating, at: now)
        value.apply(state)
        value.lastSeen = now
        context.insert(StudyActivity(wordID: word.id, date: now, kind: "revisão"))
        saveProgress()
        if wasMastered != state.mastered { rebuild(settings: settings) }
    }
    func speak(_ word: Word) {
        do { try speech.speak(word.japanese, rate: settings.speechRate) }
        catch { errorMessage = error.localizedDescription }
    }
    func speakPreview(_ word: Word, rate: Double) {
        do { try speech.speak(word.japanese, rate: rate) }
        catch { errorMessage = error.localizedDescription }
    }
    func open(_ id: String) {
        guard let word = word(id) else { return }
        now = Date()
        selectedWord = word
        markSeen(word)
    }
    func activate() {
        now = Date()
        // Fuso é explícito no snapshot; uma mudança de região exige um novo cronograma.
        if settings.timeZoneID != TimeZone.current.identifier {
            var updated = settings
            updated.timeZoneID = TimeZone.current.identifier
            rebuild(settings: updated)
        } else { reschedule() }
        WidgetCenter.shared.reloadAllTimelines()
    }
    func tick() { now = Date() }

    func update(_ newSettings: StudySettings) async -> Bool {
        do { try newSettings.validate() }
        catch { errorMessage = error.localizedDescription; return false }
        var updated = newSettings
        if updated.notificationsEnabled {
            do {
                let allowed = try await notifications.requestPermission()
                if !allowed {
                    updated.notificationsEnabled = false
                    errorMessage = "As notificações não foram autorizadas. Você pode permitir o envio nos Ajustes do iPhone."
                }
            } catch { errorMessage = error.localizedDescription; return false }
        }
        let changesRotation = updated.rotationMinutes != settings.rotationMinutes || updated.weekdays != settings.weekdays ||
            updated.level != settings.level || updated.randomOrder != settings.randomOrder || updated.timeZoneID != settings.timeZoneID
        if changesRotation { return rebuild(settings: updated) }
        var value = schedule
        if updated.notificationMinutes != settings.notificationMinutes { value.notificationAnchor = Date() }
        value.settings = updated
        return commit(value)
    }

    @discardableResult private func rebuild(settings: StudySettings) -> Bool {
        let mastered = Set(records.filter { $0.reviewState.mastered }.map(\.wordID))
        var deck = Vocabulary.deck(words: words, level: settings.level, mastered: mastered,
                                   random: settings.randomOrder, seed: schedule.seed)
        // Preserva a palavra atual no início quando ela ainda é elegível.
        if let id = schedule.wordID(at: Date()), let index = deck.firstIndex(of: id) {
            deck = Array(deck[index...]) + Array(deck[..<index])
        }
        var value = WordSchedule(anchor: Date(), orderedIDs: deck, settings: settings, seed: schedule.seed)
        if schedule.pausedAt != nil { value.pause(at: value.anchor) }
        return commit(value)
    }
    @discardableResult private func commit(_ value: WordSchedule) -> Bool {
        do {
            try SharedStore.save(value)
            schedule = value
            now = Date()
            WidgetCenter.shared.reloadAllTimelines()
            reschedule()
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }
    func togglePause() {
        var value = schedule
        if value.pausedAt == nil { value.pause(at: Date()) } else { value.resume(at: Date()) }
        commit(value)
    }
    private func reschedule() {
        // Serializa escritas na fila do sistema, inclusive durante mudanças rápidas.
        let previous = rescheduleTask
        let snapshot = schedule
        rescheduleTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }
            do { notificationReport = try await notifications.schedule(snapshot, words: words) }
            catch { errorMessage = "Falha ao agendar notificações: \(error.localizedDescription)" }
        }
    }
}
