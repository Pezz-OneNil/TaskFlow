import Foundation

/// Response from Ollama generate endpoint
struct OllamaGenerateResponse: Codable {
    let model: String
    let response: String
    let done: Bool
}

/// Response from Ollama tags endpoint (list models)
struct OllamaTagsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
    let size: Int64?
    let digest: String?
}

/// HTTP client for Ollama REST API
/// Per Requirement 2B.4
public final class OllamaClient {
    
    private let baseURL: URL
    private let session: URLSession
    private let timeout: TimeInterval
    
    public init(
        baseURL: URL = URL(string: "http://localhost:11434")!,
        timeout: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.timeout = timeout
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Check if Ollama is running and accessible
    public func checkConnection() async -> Bool {
        let url = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5 // Quick check
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// List available models
    public func listModels() async -> [String] {
        let url = baseURL.appendingPathComponent("api/tags")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return []
            }
            
            let tagsResponse = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            return tagsResponse.models.map { $0.name }
        } catch {
            return []
        }
    }
    
    /// Generate text using specified model with performance options
    /// - Parameters:
    ///   - prompt: The prompt to send
    ///   - model: The model to use
    ///   - options: Optional generation options for performance tuning
    public func generate(prompt: String, model: String, options: [String: Any]? = nil) async throws -> String {
        let url = baseURL.appendingPathComponent("api/generate")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        // Add performance options if provided
        if let options = options {
            body["options"] = options
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.requestFailed(statusCode: httpResponse.statusCode)
        }
        
        let generateResponse = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return generateResponse.response
    }
    
    /// Pre-warm a model by loading it into memory
    /// This helps reduce latency on first actual request
    public func warmupModel(_ model: String) async -> Bool {
        do {
            // Send a minimal prompt to load the model
            _ = try await generate(prompt: "Hi", model: model, options: [
                "num_predict": 1  // Generate just 1 token
            ])
            return true
        } catch {
            return false
        }
    }
}

/// Ollama-specific errors
public enum OllamaError: Error, LocalizedError {
    case connectionFailed
    case invalidResponse
    case requestFailed(statusCode: Int)
    case modelNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to Ollama"
        case .invalidResponse:
            return "Invalid response from Ollama"
        case .requestFailed(let statusCode):
            return "Ollama request failed with status \(statusCode)"
        case .modelNotFound(let model):
            return "Model '\(model)' not found in Ollama"
        }
    }
}
