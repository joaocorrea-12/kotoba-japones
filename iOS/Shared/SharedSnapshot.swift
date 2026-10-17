import Foundation
import KotobaCore

struct SharedSnapshot: Codable {
    var schemaVersion = 1
    var schedule: WordSchedule
    var updatedAt: Date
}

enum SharedStore {
    static var groupID: String {
        Bundle.main.object(forInfoDictionaryKey: "KotobaAppGroup") as? String ?? "group.org.kotoba.app"
    }

    static func fileURL() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw SharedError.missingGroup
        }
        return container.appendingPathComponent("schedule-v1.json")
    }

    static func load() throws -> SharedSnapshot? {
        let url = try fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let snapshot = try JSONDecoder().decode(SharedSnapshot.self, from: Data(contentsOf: url))
        guard snapshot.schemaVersion == 1 else { throw SettingsError.invalidSchedule }
        try snapshot.schedule.validate()
        return snapshot
    }

    /// Um único escritor (app) e substituição atômica: a extensão nunca recebe JSON parcial.
    static func save(_ schedule: WordSchedule, at date: Date = Date()) throws {
        try schedule.validate()
        let snapshot = SharedSnapshot(schedule: schedule, updatedAt: date)
        let data = try JSONEncoder().encode(snapshot)
        let url = try fileURL()
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path
        )
    }

    enum SharedError: LocalizedError {
        case missingGroup
        var errorDescription: String? {
            "Não foi possível acessar o App Group. Confira a assinatura e o mesmo identificador nos dois targets do Xcode."
        }
    }
}
