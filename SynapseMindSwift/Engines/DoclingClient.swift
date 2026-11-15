import Foundation

public struct DoclingConvertResponse: Codable {
    public var status: String
    public var filename: String
    public var markdown: String
    public var char_count: Int
}

public class DoclingClient {
    public static let shared = DoclingClient()
    private let baseURL = URL(string: "https://synapse.158.178.192.168.sslip.io")!

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

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "DoclingClient", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DoclingConvertResponse.self, from: data)
                completion(.success(decoded.markdown))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
