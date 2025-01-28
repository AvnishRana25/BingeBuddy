import Foundation

struct MediaItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let description: String?
    let posterURL: String?
    let posterMedium: String?
    let posterLarge: String?
    let releaseDate: String?
    let type: MediaType
    let year: Int?
    var uniqueId: String
    
    var fullPosterURL: String? {
        // For Watchmode API, the URLs are already complete
        // Try to get the highest quality poster available
        let urls = [posterLarge, posterMedium, posterURL].compactMap { $0 }
        return urls.first(where: { !$0.isEmpty })
    }
    
    var formattedReleaseDate: String? {
        guard let releaseDate = releaseDate, !releaseDate.isEmpty else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: releaseDate) else {
            // If we can't parse the full date, try just the year
            if let year = year {
                return "Released in \(year)"
            }
            return nil
        }
        
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: date)
    }
    
    enum MediaType: String, Codable {
        case movie = "movie"
        case tvShow = "tv_series"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description = "plot_overview"
        case posterURL = "poster"
        case posterMedium = "posterMedium"
        case posterLarge = "posterLarge"
        case releaseDate = "release_date"
        case type
        case year
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        posterMedium = try container.decodeIfPresent(String.self, forKey: .posterMedium)
        posterLarge = try container.decodeIfPresent(String.self, forKey: .posterLarge)
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        type = try container.decode(MediaType.self, forKey: .type)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        uniqueId = "\(id)_\(Date().timeIntervalSince1970)"
    }
    
    init(id: Int, title: String, description: String?, posterURL: String?, releaseDate: String?, type: MediaType, year: Int?) {
        self.id = id
        self.title = title
        self.description = description
        self.posterURL = posterURL
        self.posterMedium = nil
        self.posterLarge = nil
        self.releaseDate = releaseDate
        self.type = type
        self.year = year
        self.uniqueId = "\(id)_\(Date().timeIntervalSince1970)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueId)
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.uniqueId == rhs.uniqueId
    }
} 
