// The Swift Programming Language
// https://docs.swift.org/swift-book



import Foundation

@MainActor
public struct NetworkManager {
    
    public init() {}
    
    // MARK: - Async/Await Method
    
    public func makeRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.unknown
            }
        }
        
        // Print Request Details
        print("🚀 Request: \(request)")
        if let body = request.httpBody {
            print("📤 Request Body: \(String(data: body, encoding: .utf8) ?? "")")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print Response Details
        if let httpResponse = response as? HTTPURLResponse {
            print("🔄 Response: \(httpResponse.statusCode)")
            if !(200...299).contains(httpResponse.statusCode) {
                throw NetworkError.httpError(httpResponse.statusCode)
            }
        }
        
        print("📥 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            print("❌ Decoding Error: \(error.localizedDescription)")
            throw NetworkError.decodingError
        }
    }
    
    // MARK: - Completion Handler Method
    
    public func makeRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping @Sendable (Result<T, NetworkError>) -> Void
    ) {
        Task {
            do {
                let result: T = try await makeRequest(url: url, method: method, parameters: parameters, headers: headers)
                completion(.success(result))
            } catch let error as NetworkError {
                completion(.failure(error))
            } catch {
                completion(.failure(.unknown))
            }
        }
    }
    
    // MARK: - Post Form Data
    
    public func postFormData(
        url: String,
        parameters: [String: String],
        completion: @escaping @Sendable (Result<Data, NetworkError>) -> Void
    ) {
        guard let url = URL(string: url) else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let httpBody = createFormBody(parameters: parameters, boundary: boundary)
        request.httpBody = httpBody
        
        // Print Request Details
        print("🚀 Request: \(request)")
        print("📤 Form Data Body: \(String(data: httpBody, encoding: .utf8) ?? "")")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                completion(.failure(.unknown))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🔄 Response: \(httpResponse.statusCode)")
                if !(200...299).contains(httpResponse.statusCode) {
                    completion(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ No Data Received")
                completion(.failure(.noData))
                return
            }
            
            print("📥 Response Data: \(String(data: data, encoding: .utf8) ?? "")")
            completion(.success(data))
        }
        
        task.resume()
    }
    
    private func createFormBody(parameters: [String: String], boundary: String) -> Data {
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
}

// MARK: - Supporting Types

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum NetworkError: Error {
    case invalidURL
    case httpError(Int)
    case decodingError
    case noData
    case unknown
}
