import Foundation
import CryptoKit

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let baseURL = Constants.baseURL
    private var token: String?
    
    func setToken(_ token: String) {
        self.token = token
    }
    
    func encrypt(_ string: String) -> String {
        let data = string.data(using: .utf8)!
        let key = SymmetricKey(data: Constants.encryptionKey.data(using: .utf8)!)
        do {
            let nonce = AES.GCM.Nonce() // This generates a random nonce
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
            return sealedBox.combined!.base64EncodedString()
        } catch {
            print("Encryption error: \(error)")
            return ""
        }
    }
    
    private func decrypt(_ string: String) throws -> Data {
        let data = Data(base64Encoded: string)!
        let key = SymmetricKey(data: Constants.encryptionKey.data(using: .utf8)!)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func request<T: Codable>(_ endpoint: String, method: String, body: [String: Any]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        if let token = token {
            request.addValue(token, forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                let jsonString = String(data: jsonData, encoding: .utf8)!
                let encryptedData = encrypt(jsonString)
                request.httpBody = try JSONSerialization.data(withJSONObject: ["data": encryptedData])
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                print("Error encrypting request body: \(error)")
                completion(.failure(error))
                return
            }
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let encryptedData = json["data"] as? String {
                    let decryptedData = try self.decrypt(encryptedData)
                    let decodedResponse = try JSONDecoder().decode(T.self, from: decryptedData)
                    completion(.success(decodedResponse))
                } else {
                    print("Failed to decrypt response")
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decrypt response"])
                }
            } catch {
                print("Error processing response: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}
