import Foundation

public struct ExtractionResult {
    public var summaryMarkdown: String
    public var keyTakeaways: [String]
    public var flashcards: [FlashcardModel]
    public var concepts: [ConceptModel]
}

public struct LocalNLPExtractor {
    public static func processDocument(docId: UUID, title: String, text: String, category: String) -> ExtractionResult {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        var takeaways: [String] = []
        var flashcards: [FlashcardModel] = []
        var concepts: [ConceptModel] = []
        
        let triggerVerbs = ["est", "définie par", "entraîne", "induit", "se caractérise par", "provoque", "cause", "nécessite", "indique", "contre-indique"]
        
        for line in lines {
            if line.count < 10 { continue }
            
            // Check definitions
            for verb in triggerVerbs {
                if line.lowercased().contains(" \(verb) ") {
                    let parts = line.components(separatedBy: " \(verb) ")
                    if parts.count == 2 {
                        let term = parts[0].trimmingCharacters(in: .punctuationCharacters).trimmingCharacters(in: .whitespaces)
                        let def = parts[1].trimmingCharacters(in: .whitespaces)
                        
                        if term.count > 2 && term.count < 60 && def.count > 10 {
                            takeaways.append("\(term) : \(def)")
                            
                            concepts.append(ConceptModel(
                                docId: docId,
                                term: term,
                                definition: def
                            ))
                            
                            flashcards.append(FlashcardModel(
                                docId: docId,
                                prompt: "Quelle est la définition / le mécanisme de : \(term) ?",
                                answer: "\(term) \(verb) \(def)",
                                keyTerms: [term],
                                category: category
                            ))
                        }
                    }
                }
            }
        }
        
        // Fallback if few cards found
        if flashcards.isEmpty {
            let paragraphs = text.components(separatedBy: "\n\n").filter { $0.count > 30 }
            for (idx, para) in paragraphs.prefix(5).enumerated() {
                let firstSentence = para.components(separatedBy: ".").first ?? para
                flashcards.append(FlashcardModel(
                    docId: docId,
                    prompt: "Expliquez le point clé #\(idx + 1) du cours '\(title)' :",
                    answer: firstSentence.trimmingCharacters(in: .whitespaces),
                    keyTerms: title.components(separatedBy: " "),
                    category: category
                ))
            }
        }
        
        let markdownSummary = """
        # \(title)
        
        ## Fiche de Synthèse
        
        \(takeaways.isEmpty ? text.prefix(800) : takeaways.map { "• **\($0)**" }.joined(separator: "\n\n"))
        """
        
        return ExtractionResult(
            summaryMarkdown: String(markdownSummary),
            keyTakeaways: Array(takeaways.prefix(6)),
            flashcards: flashcards,
            concepts: concepts
        )
    }
}
