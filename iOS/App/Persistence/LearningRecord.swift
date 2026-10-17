import Foundation
import SwiftData
import KotobaCore

@Model final class LearningRecord {
    @Attribute(.unique) var wordID: String
    var favorite: Bool
    var firstSeen: Date
    var lastSeen: Date
    var due: Date
    var intervalDays: Double
    var ease: Double
    var successes: Int
    var lapses: Int
    var reviewCount: Int

    init(wordID: String, now: Date) {
        self.wordID = wordID
        favorite = false
        firstSeen = now
        lastSeen = now
        due = now
        intervalDays = 0
        ease = 2.5
        successes = 0
        lapses = 0
        reviewCount = 0
    }
    var reviewState: ReviewState {
        var state = ReviewState(due: due)
        state.intervalDays = intervalDays
        state.ease = ease
        state.successes = successes
        state.lapses = lapses
        return state
    }
    func apply(_ state: ReviewState) {
        due = state.due
        intervalDays = state.intervalDays
        ease = state.ease
        successes = state.successes
        lapses = state.lapses
        reviewCount += 1
    }
}

@Model final class StudyActivity {
    var wordID: String
    var date: Date
    var kind: String
    init(wordID: String, date: Date, kind: String) {
        self.wordID = wordID
        self.date = date
        self.kind = kind
    }
}
