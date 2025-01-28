import Foundation
import Combine

class WatchmodeAPI {
    private let baseURL = "https://api.watchmode.com/v1"
    private let apiKey = "API KEY" 
    
    func fetchMovies() -> AnyPublisher<MediaResponse, Error> {
        let url = URL(string: "\(baseURL)/list-titles?apiKey=\(apiKey)&types=movie")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MediaResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchTVShows() -> AnyPublisher<MediaResponse, Error> {
        let url = URL(string: "\(baseURL)/list-titles?apiKey=\(apiKey)&types=tv_series")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MediaResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func fetchMedia(
        type: MediaItem.MediaType,
        page: Int = 1,
        sortBy: String = "popularity_desc"
    ) -> AnyPublisher<MediaResponse, APIError> {
        let endpoint = "/list-titles"
        
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "types", value: type == .movie ? "movie" : "tv_series"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sort_by", value: sortBy),
            URLQueryItem(name: "regions", value: "US"),
            URLQueryItem(name: "fields", value: "id,title,plot_overview,poster,posterMedium,posterLarge,release_date,type,year")
        ]
        
        print("API URL for page \(page): \(components?.url?.absoluteString ?? "nil")")
        
        guard let url = components?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 429:
                    throw APIError.rateLimited
                case 400...499:
                    throw APIError.invalidResponse
                case 500...599:
                    throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
                default:
                    throw APIError.unknown
                }
            }
            .decode(type: MediaResponse.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                if error is DecodingError {
                    return APIError.decodingError
                }
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return APIError.networkError
                    default:
                        return APIError.serverError(urlError.localizedDescription)
                    }
                }
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }
    
    func fetchTitleDetails(id: Int) -> AnyPublisher<MediaItem, APIError> {
        let endpoint = "/title/\(id)/details"
        
        var components = URLComponents(string: "\(baseURL)\(endpoint)")
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "append_to_response", value: "plot_overview,poster,poster_url")
        ]
        
        print("Fetching details for title ID: \(id)")
        print("Details API URL: \(components?.url?.absoluteString ?? "nil")")
        
        guard let url = components?.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                print("Details Response Status Code: \(httpResponse.statusCode)")
                if let responseStr = String(data: data, encoding: .utf8) {
                    print("Details Response Data: \(responseStr)")
                }
                
                switch httpResponse.statusCode {
                case 200:
                    return data
                case 429:
                    throw APIError.rateLimited
                case 400...499:
                    throw APIError.invalidResponse
                case 500...599:
                    throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
                default:
                    throw APIError.unknown
                }
            }
            .decode(type: MediaItem.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                if error is DecodingError {
                    return APIError.decodingError
                }
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return APIError.networkError
                    default:
                        return APIError.serverError(urlError.localizedDescription)
                    }
                }
                return APIError.unknown
            }
            .eraseToAnyPublisher()
    }
}

struct MediaResponse: Codable {
    let titles: [MediaItem]
    let page: Int
    let totalResults: Int
    let totalPages: Int
    
    private enum CodingKeys: String, CodingKey {
        case titles
        case page
        case totalResults = "total_results"
        case totalPages = "total_pages"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        titles = try container.decode([MediaItem].self, forKey: .titles)
        page = try container.decode(Int.self, forKey: .page)
        totalResults = try container.decode(Int.self, forKey: .totalResults)
        totalPages = try container.decode(Int.self, forKey: .totalPages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(titles, forKey: .titles)
        try container.encode(page, forKey: .page)
        try container.encode(totalResults, forKey: .totalResults)
        try container.encode(totalPages, forKey: .totalPages)
    }
} 
