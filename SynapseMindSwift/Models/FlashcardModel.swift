import Foundation

public enum FlashcardState: String, Codable {
    case new = "new"
    case learning = "learning"
    case review = "review"
    case mastered = "mastered"
}

public struct FlashcardModel: Identifiable, Codable {
    public var id: UUID
    public var docId: UUID
    public var prompt: String
    public var answer: String
    public var keyTerms: [String]
    public var category: String
    public var intervalDays: Int
    public var repetitionCount: Int
    public var easinessFactor: Double
    public var nextDueDate: Date
    public var state: FlashcardState

    public init(
        id: UUID = UUID(),
        docId: UUID,
        prompt: String,
        answer: String,
        keyTerms: [String] = [],
        category: String = "Général",
        intervalDays: Int = 1,
        repetitionCount: Int = 0,
        easinessFactor: Double = 2.5,
        nextDueDate: Date = Date(),
        state: FlashcardState = .new
    ) {
        self.id = id
        self.docId = docId
        self.prompt = prompt
        self.answer = answer
        self.keyTerms = keyTerms
        self.category = category
        self.intervalDays = intervalDays
        self.repetitionCount = repetitionCount
        self.easinessFactor = easinessFactor
        self.nextDueDate = nextDueDate
        self.state = state
    }
}
