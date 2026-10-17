import XCTest
import SwiftData
import KotobaCore
@testable import Kotoba

@MainActor final class PersistenceTests: XCTestCase {
    func testFavoriteAndReviewRoundTrip() throws {
        let schema = Schema([LearningRecord.self, StudyActivity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let record = LearningRecord(wordID: "k001", now: now)
        record.favorite = true
        var state = record.reviewState
        state.rate(.good, at: now)
        record.apply(state)
        context.insert(record)
        context.insert(StudyActivity(wordID: record.wordID, date: now, kind: "revisão"))
        try context.save()
        let anotherContext = ModelContext(container)
        let saved = try XCTUnwrap(anotherContext.fetch(FetchDescriptor<LearningRecord>()).first)
        XCTAssertTrue(saved.favorite)
        XCTAssertEqual(saved.successes, 1)
        XCTAssertEqual(saved.due, now.addingTimeInterval(86400))
        XCTAssertEqual(try anotherContext.fetchCount(FetchDescriptor<StudyActivity>()), 1)
    }
    func testSharedSnapshotRoundTrip() throws {
        let schedule = WordSchedule(anchor: Date(), orderedIDs: ["k001"], settings: StudySettings())
        let snapshot = SharedSnapshot(schedule: schedule, updatedAt: Date())
        let decoded = try JSONDecoder().decode(SharedSnapshot.self, from: JSONEncoder().encode(snapshot))
        try decoded.schedule.validate()
        XCTAssertEqual(decoded.schedule, schedule)
        XCTAssertEqual(decoded.schemaVersion, 1)
    }
}
