import Foundation

public enum ReviewRating: Int, CaseIterable, Sendable {
    case again, hard, good, easy
    public var title: String {
        switch self { case .again: return "Novamente"; case .hard: return "Difícil"; case .good: return "Bom"; case .easy: return "Fácil" }
    }
}

/// Variante simples e documentada de SM-2, sem alegação de equivalência ao FSRS.
public struct ReviewState: Codable, Equatable, Sendable {
    public var due: Date
    public var intervalDays: Double = 0
    public var ease: Double = 2.5
    public var successes = 0
    public var lapses = 0
    public init(due: Date) { self.due = due }
    public var mastered: Bool { successes >= 5 && intervalDays >= 21 }

    public mutating func rate(_ rating: ReviewRating, at now: Date) {
        switch rating {
        case .again:
            lapses += 1
            successes = 0
            ease = max(1.3, ease - 0.2)
            intervalDays = 0
            due = now.addingTimeInterval(10 * 60)
            return
        case .hard:
            ease = max(1.3, ease - 0.15)
            intervalDays = max(1, intervalDays * 1.2)
        case .good:
            successes += 1
            intervalDays = intervalDays == 0 ? 1 : (successes == 2 ? 3 : intervalDays * ease)
        case .easy:
            successes += 1
            ease = min(3.0, ease + 0.15)
            intervalDays = intervalDays == 0 ? 4 : intervalDays * ease * 1.3
        }
        intervalDays = min(365, intervalDays)
        due = now.addingTimeInterval(intervalDays * 86400)
    }
}
