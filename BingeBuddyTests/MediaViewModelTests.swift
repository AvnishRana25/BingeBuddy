import XCTest
@testable import BingeBuddy

final class MediaViewModelTests: XCTestCase {
    
    enum SortOrder: String, CaseIterable {
        case popularityDesc = "popularity_desc"
        case titleAsc = "title_asc"
    }
    
    func testMediaFetching() async throws {
        // Test different media types and sort orders
        for type in [MediaItem.MediaType.movie, .tvShow] {
            for sortOrder in SortOrder.allCases {
                let api = WatchmodeAPI()
                let publisher = api.fetchMedia(type: type, sortBy: sortOrder.rawValue)
                let response = try await publisher.async()
                
                // Verify response
                XCTAssertFalse(response.titles.isEmpty)
                XCTAssertTrue(response.titles.allSatisfy { $0.type == type })
            }
        }
    }
} 
