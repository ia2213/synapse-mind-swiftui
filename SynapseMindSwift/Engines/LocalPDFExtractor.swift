import Foundation
import PDFKit

public struct LocalPDFExtractor {
    public static func extractText(from pdfData: Data) -> String {
        guard let document = PDFDocument(data: pdfData) else {
            return ""
        }
        
        var pagesText: [String] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let pageString = page.string, !pageString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                pagesText.append("### Page \(i + 1)\n" + pageString)
            }
        }
        
        return pagesText.joined(separator: "\n\n")
    }
}
