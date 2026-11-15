import Foundation

public struct ConceptModel: Identifiable, Codable {
    public var id: UUID
    public var docId: UUID
    public var term: String
    public var definition: String
    public var importanceScore: Double

    public init(
        id: UUID = UUID(),
        docId: UUID,
        term: String,
        definition: String,
        importanceScore: Double = 1.0
    ) {
        self.id = id
        self.docId = docId
        self.term = term
        self.definition = definition
        self.importanceScore = importanceScore
    }
}

public struct SynapticLinkModel: Identifiable, Codable {
    public var id: UUID
    public var sourceDocId: UUID
    public var targetDocId: UUID
    public var sourceTerm: String
    public var targetTerm: String
    public var explanation: String
    public var similarityScore: Double

    public init(
        id: UUID = UUID(),
        sourceDocId: UUID,
        targetDocId: UUID,
        sourceTerm: String,
        targetTerm: String,
        explanation: String,
        similarityScore: Double = 0.8
    ) {
        self.id = id
        self.sourceDocId = sourceDocId
        self.targetDocId = targetDocId
        self.sourceTerm = sourceTerm
        self.targetTerm = targetTerm
        self.explanation = explanation
        self.similarityScore = similarityScore
    }
}
