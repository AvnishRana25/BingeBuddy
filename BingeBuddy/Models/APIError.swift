import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError
    case decodingError
    case rateLimited
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError:
            return "Network error occurred."
        case .decodingError:
            return "Error decoding data"
        case .rateLimited:
            return "Too many requests. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
} 
