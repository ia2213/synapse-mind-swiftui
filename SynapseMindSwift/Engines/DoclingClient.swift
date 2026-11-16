import Foundation
import PDFKit

public struct DoclingConvertResponse: Codable {
    public var status: String
    public var filename: String
    public var markdown: String
    public var char_count: Int
}

public class DoclingClient: NSObject, URLSessionDelegate {
    public static let shared = DoclingClient()
    private let baseURL = URL(string: "https://synapse.158.178.192.168.sslip.io")!
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    public func convertDocument(fileData: Data, filename: String, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/api/docling/convert")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        session.dataTask(with: request) { [weak self] data, response, error in
            if let _ = error {
                // Fallback instantané en local sur PDFKit si le serveur Docling distant rencontre une erreur TLS/Réseau
                self?.fallbackToLocalPDF(fileData: fileData, completion: completion)
                return
            }

            guard let data = data else {
                self?.fallbackToLocalPDF(fileData: fileData, completion: completion)
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DoclingConvertResponse.self, from: data)
                if !decoded.markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    completion(.success(decoded.markdown))
                } else {
                    self?.fallbackToLocalPDF(fileData: fileData, completion: completion)
                }
            } catch {
                self?.fallbackToLocalPDF(fileData: fileData, completion: completion)
            }
        }.resume()
    }
    
    private func fallbackToLocalPDF(fileData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let localText = LocalPDFExtractor.extractText(from: fileData)
        if !localText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completion(.success(localText))
        } else {
            completion(.failure(NSError(domain: "PDFExtractor", code: 422, userInfo: [NSLocalizedDescriptionKey: "Impossible d'extraire le texte du PDF (Fichier vide ou protégé)"])))
        }
    }
    
    // Ignorer les erreurs TLS strictes sur les domaines IP/sslip.io (Custom Trust)
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
