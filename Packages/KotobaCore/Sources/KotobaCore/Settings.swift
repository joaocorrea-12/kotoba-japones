import Foundation

public enum Appearance: String, Codable, CaseIterable, Sendable {
    case automatic, light, dark
    public var title: String {
        switch self { case .automatic: return "Automático"; case .light: return "Claro"; case .dark: return "Escuro" }
    }
}

public struct StudySettings: Codable, Equatable, Sendable {
    public static let presets = [10, 20, 30, 40, 50, 60, 120, 180, 240, 360, 480, 720, 1440]
    public var rotationMinutes = 60
    public var notificationMinutes = 60
    public var notificationsEnabled = false
    public var quietEnabled = true
    public var quietStart = 22 * 60
    public var quietEnd = 8 * 60
    /// Calendar: domingo = 1, sábado = 7.
    public var weekdays: Set<Int> = Set(1...7)
    public var timeZoneID = TimeZone.current.identifier
    public var level = 5
    public var randomOrder = false
    public var showKanji = true
    public var showKana = true
    public var showRomaji = false
    public var showMeaning = true
    public var speechRate: Double = 0.45
    public var dailyGoal = 5
    public var appearance: Appearance = .automatic
    public init() {}

    public func validate() throws {
        guard (1...10_080).contains(rotationMinutes), (1...10_080).contains(notificationMinutes) else {
            throw SettingsError.invalidInterval
        }
        guard !weekdays.isEmpty, weekdays.isSubset(of: Set(1...7)) else { throw SettingsError.noWeekdays }
        guard (1...5).contains(level), TimeZone(identifier: timeZoneID) != nil,
              (0..<1440).contains(quietStart), (0..<1440).contains(quietEnd),
              !quietEnabled || quietStart != quietEnd,
              speechRate.isFinite, (0.2...0.6).contains(speechRate), (1...100).contains(dailyGoal)
        else { throw SettingsError.invalidValue }
    }

    public var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: timeZoneID) ?? .current
        return result
    }
    public func allowsNotification(at date: Date) -> Bool {
        guard weekdays.contains(calendar.component(.weekday, from: date)) else { return false }
        guard quietEnabled else { return true }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        if quietStart < quietEnd { return !(quietStart..<quietEnd).contains(minute) }
        return minute < quietStart && minute >= quietEnd
    }
}

public enum SettingsError: LocalizedError {
    case invalidInterval, noWeekdays, invalidValue, invalidSchedule
    public var errorDescription: String? {
        switch self {
        case .invalidInterval: return "Escolha um intervalo entre 1 minuto e 7 dias."
        case .noWeekdays: return "Selecione pelo menos um dia de estudo."
        case .invalidValue: return "Confira os horários, o fuso e os valores informados. O início e o fim do silêncio devem ser diferentes."
        case .invalidSchedule: return "O cronograma salvo não pôde ser lido. Abra o app para configurá-lo novamente."
        }
    }
}
