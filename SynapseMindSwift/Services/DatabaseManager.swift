import Foundation
import Combine

public class DatabaseManager: ObservableObject {
    public static let shared = DatabaseManager()

    @Published public var documents: [DocumentModel] = []
    @Published public var flashcards: [FlashcardModel] = []
    @Published public var concepts: [ConceptModel] = []
    @Published public var synapticLinks: [SynapticLinkModel] = []

    private let fileManager = FileManager.default
    private var docsStorageURL: URL {
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return folder.appendingPathComponent("synapse_docs.json")
    }
    private var cardsStorageURL: URL {
        let folder = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return folder.appendingPathComponent("synapse_cards.json")
    }

    public init() {
        loadData()
        if documents.isEmpty {
            seedSampleData()
        }
    }

    public func loadData() {
        do {
            if fileManager.fileExists(atPath: docsStorageURL.path) {
                let data = try Data(contentsOf: docsStorageURL)
                documents = try JSONDecoder().decode([DocumentModel].self, from: data)
            }
            if fileManager.fileExists(atPath: cardsStorageURL.path) {
                let data = try Data(contentsOf: cardsStorageURL)
                flashcards = try JSONDecoder().decode([FlashcardModel].self, from: data)
            }
        } catch {
            print("Error loading local database: \(error)")
        }
    }

    public func saveData() {
        do {
            let docsData = try JSONEncoder().encode(documents)
            try docsData.write(to: docsStorageURL)

            let cardsData = try JSONEncoder().encode(flashcards)
            try cardsData.write(to: cardsStorageURL)
        } catch {
            print("Error saving local database: \(error)")
        }
    }

    public func addDocument(title: String, category: String, text: String) {
        let docId = UUID()
        let result = LocalNLPExtractor.processDocument(
            docId: docId,
            title: title,
            text: text,
            category: category
        )

        var newDoc = DocumentModel(
            id: docId,
            title: title,
            category: category,
            fullText: text,
            summaryMarkdown: result.summaryMarkdown,
            keyTakeaways: result.keyTakeaways,
            createdAt: Date(),
            flashcardsCount: result.flashcards.count,
            avgMastery: 0.0
        )

        documents.append(newDoc)
        flashcards.append(contentsOf: result.flashcards)
        concepts.append(contentsOf: result.concepts)

        // Generate synaptic cross-links
        generateSynapticLinks()

        saveData()
    }

    public func updateFlashcard(_ updatedCard: FlashcardModel) {
        if let idx = flashcards.firstIndex(where: { $0.id == updatedCard.id }) {
            flashcards[idx] = updatedCard

            // Recalculate avg mastery for parent document
            let docCards = flashcards.filter { $0.docId == updatedCard.docId }
            let masteredCount = docCards.filter { $0.state == .mastered || $0.state == .review }.count
            let avg = docCards.isEmpty ? 0.0 : (Double(masteredCount) / Double(docCards.count)) * 100.0

            if let docIdx = documents.firstIndex(where: { $0.id == updatedCard.docId }) {
                documents[docIdx].avgMastery = avg
            }

            saveData()
        }
    }

    public func deleteDocument(_ docId: UUID) {
        documents.removeAll { $0.id == docId }
        flashcards.removeAll { $0.docId == docId }
        concepts.removeAll { $0.docId == docId }
        synapticLinks.removeAll { $0.sourceDocId == docId || $0.targetDocId == docId }
        saveData()
    }

    private func generateSynapticLinks() {
        var links: [SynapticLinkModel] = []
        for i in 0..<concepts.count {
            for j in (i + 1)..<concepts.count {
                let c1 = concepts[i]
                let c2 = concepts[j]
                if c1.docId != c2.docId {
                    if c1.term.lowercased().contains(c2.term.lowercased()) || c2.term.lowercased().contains(c1.term.lowercased()) {
                        links.append(SynapticLinkModel(
                            sourceDocId: c1.docId,
                            targetDocId: c2.docId,
                            sourceTerm: c1.term,
                            targetTerm: c2.term,
                            explanation: "Lien conceptuel entre \(c1.term) et \(c2.term)"
                        ))
                    }
                }
            }
        }
        self.synapticLinks = links
    }

    private func seedSampleData() {
        addDocument(
            title: "Insuffisance Cardiaque R2C",
            category: "Cardiologie",
            text: """
            L'insuffisance cardiaque est caractérisée par l'incapacité du cœur à assurer un débit sanguin suffisant.
            L'Echocardiographie transthoracique est l'examen clé qui confirme le diagnostic et évalue la FEVG.
            Le BNP ou NT-proBNP est un marqueur biologique de stretch ventriculaire.
            Les IEC et Bêta-bloquants constituent le traitement médical de première intention.
            """
        )
        addDocument(
            title: "Sténose Aortique Serrée",
            category: "Cardiologie",
            text: """
            La sténose aortique est définie par un rétrécissement de la surface valvulaire aortique < 1.0 cm2.
            La triade fonctionnelle classique associe Angor, Syncope d'effort et Dyspnée.
            Le TAVI ou le remplacement valvulaire chirurgical (SAVR) est le traitement curatif.
            """
        )
    }
}
