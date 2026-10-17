import Foundation

/// Valor imutável para leitores: app, extensão e notificações recebem o mesmo snapshot.
public struct WordSchedule: Codable, Equatable, Sendable {
    public var anchor: Date
    public var orderedIDs: [String]
    public var settings: StudySettings
    public var seed: UInt64
    public var pausedAt: Date?
    public var pausedStudySeconds: TimeInterval = 0
    public var notificationAnchor: Date

    public init(anchor: Date, orderedIDs: [String], settings: StudySettings, seed: UInt64 = 1) {
        self.anchor = anchor
        self.orderedIDs = orderedIDs
        self.settings = settings
        self.seed = seed
        self.notificationAnchor = anchor
    }

    public func validate() throws {
        try settings.validate()
        guard !orderedIDs.isEmpty, Set(orderedIDs).count == orderedIDs.count,
              anchor.timeIntervalSince1970.isFinite,
              notificationAnchor.timeIntervalSince1970.isFinite,
              pausedStudySeconds.isFinite, pausedStudySeconds >= 0,
              pausedAt.map({ $0 >= anchor && $0.timeIntervalSince1970.isFinite }) ?? true
        else { throw SettingsError.invalidSchedule }
    }

    /// Tempo transcorrido apenas em dias ativos; usa o calendário para respeitar dias de 23/25h.
    public func activeSeconds(from start: Date, to end: Date) -> TimeInterval {
        guard end > start else { return 0 }
        let calendar = settings.calendar
        var cursor = start
        var total: TimeInterval = 0
        while cursor < end {
            guard let day = calendar.dateInterval(of: .day, for: cursor) else { break }
            let boundary = min(day.end, end)
            if settings.weekdays.contains(calendar.component(.weekday, from: cursor)) {
                total += boundary.timeIntervalSince(cursor)
            }
            guard boundary > cursor else { break }
            cursor = boundary
        }
        return total
    }

    public func advanceActive(from start: Date, seconds: TimeInterval) -> Date {
        let calendar = settings.calendar
        var cursor = start
        var remaining = max(0, seconds)
        // Pelo menos um dia ativo é obrigatório na validação.
        guard !settings.weekdays.isEmpty else { return start }
        while true {
            guard let day = calendar.dateInterval(of: .day, for: cursor) else { return cursor }
            if settings.weekdays.contains(calendar.component(.weekday, from: cursor)) {
                let available = day.end.timeIntervalSince(cursor)
                // Se cair exatamente no início de um dia inativo, vá ao próximo dia ativo.
                if remaining < available { return cursor.addingTimeInterval(remaining) }
                remaining -= available
            }
            cursor = day.end
        }
    }

    public func slot(at date: Date) -> Int {
        let effective = pausedAt ?? date
        var elapsed = max(0, activeSeconds(from: anchor, to: effective) - pausedStudySeconds)
        if !settings.weekdays.contains(settings.calendar.component(.weekday, from: effective)), elapsed > 0 {
            elapsed = max(0, elapsed - 0.000_001)
        }
        return Int(floor(elapsed / Double(max(1, settings.rotationMinutes) * 60)))
    }

    public func wordID(at date: Date) -> String? {
        guard !orderedIDs.isEmpty else { return nil }
        return orderedIDs[slot(at: date) % orderedIDs.count]
    }

    public func nextChange(after date: Date) -> Date? {
        guard pausedAt == nil, !orderedIDs.isEmpty else { return nil }
        let elapsed = max(0, activeSeconds(from: anchor, to: date) - pausedStudySeconds)
        let interval = Double(max(1, settings.rotationMinutes) * 60)
        let remaining = max(0, Double(slot(at: date) + 1) * interval - elapsed)
        return advanceActive(from: max(date, anchor), seconds: remaining)
    }

    public mutating func pause(at date: Date) { if pausedAt == nil { pausedAt = max(date, anchor) } }
    public mutating func resume(at date: Date) {
        guard let pausedAt else { return }
        pausedStudySeconds += activeSeconds(from: pausedAt, to: max(pausedAt, date))
        self.pausedAt = nil
    }

    /// Histórico do cronograma, separado do registro de palavras realmente estudadas.
    public func recentIDs(at date: Date, limit: Int = 30) -> [String] {
        guard !orderedIDs.isEmpty else { return [] }
        let current = slot(at: date)
        return (0..<min(max(0, limit), current + 1)).map { orderedIDs[(current - $0) % orderedIDs.count] }
    }
}

public struct NotificationPlan: Equatable, Sendable {
    public let date: Date
    public let wordID: String
}

public enum NotificationPlanner {
    /// Janela finita: reabertura e mudanças de configuração renovam a fila.
    /// 60 deixa margem no limite conservador de 64 notificações pendentes do iOS.
    public static func plan(schedule: WordSchedule, after now: Date, capacity: Int = 60) -> [NotificationPlan] {
        guard schedule.settings.notificationsEnabled, schedule.pausedAt == nil else { return [] }
        let step = Double(max(1, schedule.settings.notificationMinutes) * 60)
        let elapsed = max(0, now.timeIntervalSince(schedule.notificationAnchor))
        var candidate = schedule.notificationAnchor.addingTimeInterval((floor(elapsed / step) + 1) * step)
        let horizon = now.addingTimeInterval(30 * 86400)
        var result: [NotificationPlan] = []
        while result.count < min(60, max(0, capacity)), candidate <= horizon {
            if schedule.settings.allowsNotification(at: candidate), let id = schedule.wordID(at: candidate) {
                result.append(NotificationPlan(date: candidate, wordID: id))
            }
            candidate = candidate.addingTimeInterval(step)
        }
        return result
    }
}
