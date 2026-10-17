import XCTest
@testable import KotobaCore

final class CoreTests: XCTestCase {
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private func schedule(minutes: Int = 10) -> WordSchedule {
        var settings = StudySettings()
        settings.timeZoneID = "UTC"
        settings.rotationMinutes = minutes
        return WordSchedule(anchor: date("2026-10-16T12:00:00Z"), orderedIDs: ["a", "b", "c"], settings: settings)
    }
    func testExactBoundaryAndWrap() {
        let s = schedule()
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(599)), "a")
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(600)), "b")
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(1800)), "a")
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(-10)), "a")
    }
    func testEveryPresetAndCustom() throws {
        for minutes in StudySettings.presets + [1, 73, 10_080] {
            let s = schedule(minutes: minutes)
            try s.validate()
            XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(Double(minutes * 60))), "b")
            XCTAssertEqual(s.nextChange(after: s.anchor), s.anchor.addingTimeInterval(Double(minutes * 60)))
        }
    }
    func testRestorationAfterLongAbsence() throws {
        let s = schedule()
        let restored = try JSONDecoder().decode(WordSchedule.self, from: JSONEncoder().encode(s))
        let later = s.anchor.addingTimeInterval(99 * 86400 + 1234)
        XCTAssertEqual(s.wordID(at: later), restored.wordID(at: later))
    }
    func testPauseAndResumePreservePartialInterval() {
        var s = schedule()
        s.pause(at: s.anchor.addingTimeInterval(300))
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(9000)), "a")
        XCTAssertNil(s.nextChange(after: s.anchor))
        s.resume(at: s.anchor.addingTimeInterval(3900))
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(4199)), "a")
        XCTAssertEqual(s.wordID(at: s.anchor.addingTimeInterval(4200)), "b")
    }
    func testWeekendFreezesAndBoundaryDefers() {
        var s = schedule(minutes: 60)
        s.settings.weekdays = Set(2...6)
        let saturday = date("2026-10-17T00:00:00Z")
        let sunday = date("2026-10-18T12:00:00Z")
        let monday = date("2026-10-19T00:00:00Z")
        XCTAssertEqual(s.slot(at: saturday), 11)
        XCTAssertEqual(s.slot(at: sunday), 11)
        XCTAssertEqual(s.nextChange(after: saturday), monday)
        XCTAssertEqual(s.slot(at: monday), 12)
    }
    func testPauseAcrossWeekendDoesNotConsumeStudyTime() {
        var s = schedule(minutes: 60)
        s.settings.weekdays = Set(2...6)
        s.pause(at: date("2026-10-16T23:30:00Z"))
        s.resume(at: date("2026-10-19T00:30:00Z"))
        XCTAssertEqual(s.nextChange(after: date("2026-10-19T00:30:00Z")), date("2026-10-19T01:00:00Z"))
    }
    func testDaylightSavingSpringAndFall() {
        var s = schedule(minutes: 24 * 60)
        s.settings.timeZoneID = "America/New_York"
        let spring = date("2026-03-08T05:00:00Z")
        let fall = date("2026-11-01T04:00:00Z")
        XCTAssertEqual(s.activeSeconds(from: spring, to: date("2026-03-09T04:00:00Z")), 23 * 3600)
        XCTAssertEqual(s.activeSeconds(from: fall, to: date("2026-11-02T05:00:00Z")), 25 * 3600)
    }
    func testNotificationFrequencyIsIndependent() {
        var s = schedule(minutes: 10)
        s.settings.notificationMinutes = 60
        s.settings.notificationsEnabled = true
        s.settings.quietEnabled = false
        let plans = NotificationPlanner.plan(schedule: s, after: s.anchor, capacity: 2)
        XCTAssertEqual(plans.map(\.date), [s.anchor.addingTimeInterval(3600), s.anchor.addingTimeInterval(7200)])
        XCTAssertEqual(plans.map(\.wordID), ["a", "a"])
    }
    func testQuietOvernightAndInactiveDays() {
        var s = schedule()
        s.settings.notificationsEnabled = true
        s.settings.weekdays = Set(2...6)
        let now = date("2026-10-16T21:00:00Z")
        let plans = NotificationPlanner.plan(schedule: s, after: now)
        XCTAssertEqual(plans.first?.date, date("2026-10-19T08:00:00Z"))
        XCTAssertTrue(plans.allSatisfy { s.settings.allowsNotification(at: $0.date) })
    }
    func testDaytimeQuietBoundary() {
        var settings = StudySettings()
        settings.timeZoneID = "UTC"
        settings.quietStart = 12 * 60
        settings.quietEnd = 14 * 60
        XCTAssertFalse(settings.allowsNotification(at: date("2026-10-16T12:00:00Z")))
        XCTAssertTrue(settings.allowsNotification(at: date("2026-10-16T14:00:00Z")))
    }
    func testCapacityPauseAndDisabledNotifications() {
        var s = schedule()
        XCTAssertTrue(NotificationPlanner.plan(schedule: s, after: s.anchor).isEmpty)
        s.settings.notificationsEnabled = true
        XCTAssertEqual(NotificationPlanner.plan(schedule: s, after: s.anchor, capacity: 200).count, 60)
        XCTAssertTrue(NotificationPlanner.plan(schedule: s, after: s.anchor, capacity: 0).isEmpty)
        s.pause(at: s.anchor)
        XCTAssertTrue(NotificationPlanner.plan(schedule: s, after: s.anchor).isEmpty)
    }
    func testInvalidSettingsAndEmptyDeck() {
        var s = schedule()
        s.settings.weekdays = []
        XCTAssertThrowsError(try s.validate())
        s = schedule(minutes: 0)
        XCTAssertThrowsError(try s.validate())
        s = schedule(); s.orderedIDs = []
        XCTAssertThrowsError(try s.validate())
        XCTAssertNil(s.wordID(at: s.anchor))
        s = schedule(); s.settings.quietEnd = s.settings.quietStart
        XCTAssertThrowsError(try s.validate())
    }
    func testSeedIsStableAcrossProcesses() throws {
        let words = try Vocabulary.load()
        let first = Vocabulary.deck(words: words, level: 5, mastered: [], random: true, seed: 42)
        let second = Vocabulary.deck(words: words, level: 5, mastered: [], random: true, seed: 42)
        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, words.map(\.id))
        XCTAssertEqual(Vocabulary.stableHash("kotoba"), 9_766_424_910_215_455_371)
    }
    func testMasteredWordsExcludedUntilAllMastered() throws {
        let words = try Vocabulary.load()
        let deck = Vocabulary.deck(words: words, level: 5, mastered: [words[0].id], random: false, seed: 1)
        XCTAssertFalse(deck.contains(words[0].id))
        XCTAssertEqual(Vocabulary.deck(words: words, level: 5, mastered: Set(words.map(\.id)), random: false, seed: 1).count, words.count)
    }
    func testVocabularyHasCompleteUniqueEntries() throws {
        let words = try Vocabulary.load()
        XCTAssertGreaterThanOrEqual(words.count, 100)
        XCTAssertEqual(Set(words.map(\.id)).count, words.count)
        for word in words {
            XCTAssertFalse(word.kana.isEmpty)
            XCTAssertFalse(word.meaning.isEmpty)
            XCTAssertFalse(word.example.isEmpty)
            XCTAssertFalse(word.exampleMeaning.isEmpty)
            XCTAssertTrue((1...5).contains(word.jlpt))
        }
    }
    func testReviewLearningLapseAndMastery() {
        let now = date("2026-10-17T12:00:00Z")
        var state = ReviewState(due: now)
        state.rate(.good, at: now)
        XCTAssertEqual(state.intervalDays, 1)
        state.rate(.good, at: state.due)
        XCTAssertEqual(state.intervalDays, 3)
        for _ in 0..<4 { state.rate(.good, at: state.due) }
        XCTAssertTrue(state.mastered)
        state.rate(.again, at: now)
        XCTAssertEqual(state.due, now.addingTimeInterval(600))
        XCTAssertEqual(state.lapses, 1)
        XCTAssertFalse(state.mastered)
    }
    func testHardEaseFloorAndEasyCap() {
        var state = ReviewState(due: Date())
        for _ in 0..<50 { state.rate(.hard, at: Date()) }
        XCTAssertEqual(state.ease, 1.3, accuracy: 0.0001)
        for _ in 0..<50 { state.rate(.easy, at: Date()) }
        XCTAssertEqual(state.intervalDays, 365)
        XCTAssertEqual(state.ease, 3.0)
    }
}
