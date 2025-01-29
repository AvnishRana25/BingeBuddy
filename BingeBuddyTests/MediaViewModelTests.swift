import XCTest
@testable import BingeBuddy

final class MediaViewModelTests: XCTestCase {
    
    enum SortOrder: String, CaseIterable {
        case popularityDesc = "popularity_desc"
        case titleAsc = "title_asc"
    }
    
    func testMediaFetching() async throws {
        // Test each combination
        for type in [MediaItem.MediaType.movie, .tvShow] {
            for sortOrder in SortOrder.allCases {
                let api = WatchmodeAPI()
                let publisher = api.fetchMedia(type: type, sortBy: sortOrder.rawValue)
                let response = try await publisher.async()
                
                XCTAssertFalse(response.titles.isEmpty, "Response should not be empty for \(type) with sort \(sortOrder)")
                XCTAssertTrue(response.titles.allSatisfy { $0.type == type }, "All items should be of type \(type)")
            }
        }
    }
} 
