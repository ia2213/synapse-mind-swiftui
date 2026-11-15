import Foundation

public struct DocumentModel: Identifiable, Codable {
    public var id: UUID
    public var title: String
    public var category: String
    public var fullText: String
    public var summaryMarkdown: String
    public var keyTakeaways: [String]
    public var createdAt: Date
    public var flashcardsCount: Int
    public var avgMastery: Double

    public init(
        id: UUID = UUID(),
        title: String,
        category: String = "Général",
        fullText: String,
        summaryMarkdown: String = "",
        keyTakeaways: [String] = [],
        createdAt: Date = Date(),
        flashcardsCount: Int = 0,
        avgMastery: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.fullText = fullText
        self.summaryMarkdown = summaryMarkdown
        self.keyTakeaways = keyTakeaways
        self.createdAt = createdAt
        self.flashcardsCount = flashcardsCount
        self.avgMastery = avgMastery
    }
}
