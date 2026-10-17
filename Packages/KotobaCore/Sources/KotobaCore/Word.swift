import Foundation

public struct Word: Codable, Identifiable, Equatable, Sendable {
    public let id: String
    public let japanese: String
    public let kana: String
    public let romaji: String
    public let meaning: String
    public let partOfSpeech: String
    /// Estimativa pedagógica, não uma lista oficial do exame JLPT.
    public let jlpt: Int
    public let example: String
    public let exampleMeaning: String
    public let note: String
}

public enum Vocabulary {
    public static func load() throws -> [Word] {
        guard let url = Bundle.module.url(forResource: "words", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Word].self, from: Data(contentsOf: url))
    }

    public static func deck(words: [Word], level: Int, mastered: Set<String>, random: Bool, seed: UInt64) -> [String] {
        let eligible = words.filter { $0.jlpt >= level }
        let learning = eligible.filter { !mastered.contains($0.id) }
        let source = learning.isEmpty ? eligible : learning
        // A ordem editorial é a sequência progressiva; nunca use hashValue/shuffled().
        guard random else { return source.map(\.id) }
        return source.sorted {
            let a = stableHash("\(seed):\($0.id)"), b = stableHash("\(seed):\($1.id)")
            return a == b ? $0.id < $1.id : a < b
        }.map(\.id)
    }

    public static func stableHash(_ string: String) -> UInt64 {
        string.utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }
}
