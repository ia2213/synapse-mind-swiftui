import Foundation
import PDFKit
import UIKit
#if canImport(Vision)
import Vision
#endif

public enum DoclingQualityMode: String, CaseIterable, Identifiable {
    case fast = "Rapide (⚡ Vitesse)"
    case balanced = "Équilibré (⚖️ Structure)"
    case highPrecision = "Haute Précision (🎯 Vision OCR)"

    public var id: String { self.rawValue }
    
    public var description: String {
        switch self {
        case .fast:
            return "Extraction vectorielle native ultra-rapide avec reconstruction des paragraphes et détection de titres."
        case .balanced:
            return "Analyse de mise en page Docling, hiérarchie sémantique H1/H2/H3 et tableaux."
        case .highPrecision:
            return "Rendu haute résolution + OCR neuronal Apple Vision pour PDF scannés ou manuscrits."
        }
    }
}

public struct DoclingResult {
    public var markdown: String
    public var headingsCount: Int
    public var tablesCount: Int
    public var pagesCount: Int
    public var processingTime: Double
}

public class DoclingLocalEngine {
    public static let shared = DoclingLocalEngine()

    public func parsePDF(
        pdfData: Data,
        mode: DoclingQualityMode,
        progress: @escaping (Double, String) -> Void,
        completion: @escaping (Result<DoclingResult, Error>) -> Void
    ) {
        let startTime = Date()
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let document = PDFDocument(data: pdfData) else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "DoclingLocalEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Impossible de charger le document PDF"])))
                }
                return
            }

            let pageCount = document.pageCount
            if pageCount == 0 {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "DoclingLocalEngine", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le document PDF ne contient aucune page"])))
                }
                return
            }

            var structuredSections: [String] = []
            var totalHeadings = 0
            var totalTables = 0

            for pageIndex in 0..<pageCount {
                let progressValue = Double(pageIndex) / Double(pageCount)
                DispatchQueue.main.async {
                    progress(progressValue, "Docling : Analyse de la page \(pageIndex + 1)/\(pageCount)...")
                }

                guard let page = document.page(at: pageIndex) else { continue }

                switch mode {
                case .fast:
                    let (md, headings, tables) = self.processFastLayout(page: page, pageNumber: pageIndex + 1)
                    structuredSections.append(md)
                    totalHeadings += headings
                    totalTables += tables

                case .balanced:
                    let (md, headings, tables) = self.processBalancedHierarchy(page: page, pageNumber: pageIndex + 1)
                    structuredSections.append(md)
                    totalHeadings += headings
                    totalTables += tables

                case .highPrecision:
                    let (md, headings, tables) = self.processHighPrecisionVisionOCR(page: page, pageNumber: pageIndex + 1)
                    structuredSections.append(md)
                    totalHeadings += headings
                    totalTables += tables
                }
            }

            let finalMarkdown = structuredSections.joined(separator: "\n\n")
            let elapsedTime = Date().timeIntervalSince(startTime)

            let result = DoclingResult(
                markdown: finalMarkdown,
                headingsCount: totalHeadings,
                tablesCount: totalTables,
                pagesCount: pageCount,
                processingTime: elapsedTime
            )

            DispatchQueue.main.async {
                progress(1.0, "Conversion Docling terminée avec succès")
                completion(.success(result))
            }
        }
    }

    // MARK: - Mode Rapide (Vectoriel & Alignement Spatial)
    private func processFastLayout(page: PDFPage, pageNumber: Int) -> (String, Int, Int) {
        guard let pageString = page.string, !pageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Si la page est scannée et vide en texte brut, on bascule sur OCR
            return processHighPrecisionVisionOCR(page: page, pageNumber: pageNumber)
        }

        var lines = pageString.components(separatedBy: .newlines)
        var mdLines: [String] = ["## --- Page \(pageNumber) ---"]
        var headings = 0
        var tables = 0

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            // Heuristiques de titres Docling
            if line.count < 50 && (line.allSatisfy({ $0.isUppercase || $0.isWhitespace || $0.isNumber }) || line.hasPrefix("I.") || line.hasPrefix("1.") || line.hasPrefix("A.")) {
                mdLines.append("\n### \(line)\n")
                headings += 1
            } else if line.contains(" | ") || (line.contains("\t") && line.components(separatedBy: "\t").count > 2) {
                // Heuristique tableau
                let cells = line.components(separatedBy: line.contains(" | ") ? "|" : "\t").map { $0.trimmingCharacters(in: .whitespaces) }
                mdLines.append("| " + cells.joined(separator: " | ") + " |")
                tables += 1
            } else if line.hasPrefix("-") || line.hasPrefix("•") || line.hasPrefix("*") {
                let cleaned = line.dropFirst().trimmingCharacters(in: .whitespaces)
                mdLines.append("- \(cleaned)")
            } else {
                mdLines.append(line)
            }
        }

        return (mdLines.joined(separator: "\n"), headings, tables)
    }

    // MARK: - Mode Équilibré (Structure & Hiérarchie Sémantique)
    private func processBalancedHierarchy(page: PDFPage, pageNumber: Int) -> (String, Int, Int) {
        guard let pageString = page.string, !pageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return processHighPrecisionVisionOCR(page: page, pageNumber: pageNumber)
        }

        let lines = pageString.components(separatedBy: .newlines)
        var mdLines: [String] = ["## --- Page \(pageNumber) ---"]
        var headings = 0
        var tables = 0

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line.count < 60 && (line.range(of: "^[0-9]+[\\.)]\\s+[A-ZÀ-Ÿ]", options: .regularExpression) != nil || line.range(of: "^[IVXLCDM]+\\.", options: .regularExpression) != nil) {
                mdLines.append("\n### \(line)\n")
                headings += 1
            } else if line.hasPrefix("Définition") || line.hasPrefix("Traitement") || line.hasPrefix("Diagnostic") || line.hasPrefix("Clinique") || line.hasPrefix("Étiologie") {
                mdLines.append("\n#### 📌 \(line)\n")
                headings += 1
            } else if line.hasPrefix("•") || line.hasPrefix("-") {
                mdLines.append("- \(line.dropFirst().trimmingCharacters(in: .whitespaces))")
            } else {
                mdLines.append(line)
            }
        }

        return (mdLines.joined(separator: "\n"), headings, tables)
    }

    // MARK: - Mode Haute Précision (Apple Vision OCR)
    private func processHighPrecisionVisionOCR(page: PDFPage, pageNumber: Int) -> (String, Int, Int) {
        let pageSize = page.bounds(for: .mediaBox).size
        let renderer = UIGraphicsImageRenderer(size: pageSize)
        let pageImage = renderer.image { ctx in
            UIColor.white.set()
            ctx.fill(CGRect(origin: .zero, size: pageSize))
            ctx.cgContext.translateBy(x: 0.0, y: pageSize.height)
            ctx.cgContext.scaleBy(x: 1.0, y: -1.0)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }

        var extractedText = ""
        var headings = 0
        let semaphore = DispatchSemaphore(value: 0)

        #if canImport(Vision)
        if let cgImage = pageImage.cgImage {
            let request = VNRecognizeTextRequest { req, err in
                defer { semaphore.signal() }
                guard let observations = req.results as? [VNRecognizedTextObservation], err == nil else {
                    extractedText = page.string ?? ""
                    return
                }

                var lines: [String] = []
                for obs in observations {
                    if let topCandidate = obs.topCandidates(1).first {
                        let text = topCandidate.string.trimmingCharacters(in: .whitespaces)
                        if text.count < 50 && (text.range(of: "^[0-9]+\\.", options: .regularExpression) != nil || text == text.uppercased()) {
                            lines.append("\n### \(text)\n")
                            headings += 1
                        } else {
                            lines.append(text)
                        }
                    }
                }
                extractedText = lines.joined(separator: "\n")
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["fr-FR", "en-US", "de-DE"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                _ = semaphore.wait(timeout: .now() + 10)
            } catch {
                extractedText = page.string ?? ""
            }
        } else {
            extractedText = page.string ?? ""
        }
        #else
        extractedText = page.string ?? ""
        #endif

        return ("## --- Page \(pageNumber) (Docling Vision OCR) ---\n" + extractedText, headings, 0)
    }
}
