import Foundation
import Combine
public enum ErrorAction {
    case retry, ignore
}

class MediaViewModel: ObservableObject {
    @Published var movies: [MediaItem] = []
    @Published var tvShows: [MediaItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: APIError?
    @Published var showError = false
    @Published var errorTitle = ""
    @Published var errorMessage = ""
    @Published var errorAction: ErrorAction = .retry
    
    private let api = WatchmodeAPI()
    private var cancellables = Set<AnyCancellable>()
    
    private var currentMoviePage = 1
    private var currentTVShowPage = 1
    private var hasMoreMovies = true
    private var hasMoreTVShows = true
    
    private var lastMovieSortIndex = 0
    private var lastTVSortIndex = 0
    private var lastMoviePage = 1
    private var lastTVPage = 1
    
    private let sortOptions = [
        "popularity_desc",
        "relevance_desc",
        "release_date_desc",
        "year_desc",
        "rating_desc"
    ]
    
    private var randomOffset: Int {
        Int.random(in: 1...5)
    }
    
    private func handleError(_ error: Error, type: MediaItem.MediaType) {
        let apiError = error as? APIError ?? .serverError(error.localizedDescription)
        
        switch apiError {
        case .networkError:
            errorTitle = "Network Error"
            errorMessage = "Please check your internet availibity and try again."
            errorAction = .retry
            
        case .serverError(let message):
            errorTitle = "Server Error"
            errorMessage = message
            errorAction = .retry
            
        case .invalidResponse:
            errorTitle = "Data Error"
            errorMessage = "Unable to load \(type == .movie ? "movies" : "TV shows"). Please try again."
            errorAction = .retry
            
        case .rateLimited:
            errorTitle = "Too Much Requests"
            errorMessage = "Please wait a moment before trying again."
            errorAction = .ignore
            
        default:
            errorTitle = "Unexpected Error"
            errorMessage = "Something went wrong. Trying To Figure Out"
            errorAction = .retry
        }
        
        self.error = apiError
        self.showError = true
    }
    
    private func fetchContent(type: MediaItem.MediaType, page: Int, sortBy: String) async throws -> MediaResponse {
        try await withCheckedThrowingContinuation { continuation in
            api.fetchMedia(type: type, page: page, sortBy: sortBy)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { response in
                        continuation.resume(returning: response)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    private func fetchParallelContent(type: MediaItem.MediaType) -> AnyPublisher<(MediaResponse, MediaResponse), APIError> {
        Publishers.Zip(
            api.fetchMedia(type: type, page: 1, sortBy: "popularity_desc"),
            api.fetchMedia(type: type, page: 1, sortBy: "release_date_desc")
        )
        .catch { error -> AnyPublisher<(MediaResponse, MediaResponse), APIError> in
            return Fail(error: error).eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    @MainActor
    func refreshContent(for type: MediaItem.MediaType) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        showError = false
        
        do {
            let (popularResponse, recentResponse) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(MediaResponse, MediaResponse), Error>) in
                fetchParallelContent(type: type)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { response in
                            continuation.resume(returning: response)
                        }
                    )
                    .store(in: &cancellables)
            }
            
            if type == .movie {
                var allMovies = Set<MediaItem>()
                popularResponse.titles.forEach { movie in
                    var modifiedMovie = movie
                    modifiedMovie.uniqueId = "\(movie.id)_\(Date().timeIntervalSince1970)"
                    allMovies.insert(modifiedMovie)
                }
                recentResponse.titles.forEach { movie in
                    var modifiedMovie = movie
                    modifiedMovie.uniqueId = "\(movie.id)_\(Date().timeIntervalSince1970)"
                    allMovies.insert(modifiedMovie)
                }
                self.movies = Array(allMovies).shuffled()
                self.hasMoreMovies = popularResponse.page < popularResponse.totalPages
                self.currentMoviePage = 2
            } else {
                var allShows = Set<MediaItem>()
                popularResponse.titles.forEach { show in
                    var modifiedShow = show
                    modifiedShow.uniqueId = "\(show.id)_\(Date().timeIntervalSince1970)"
                    allShows.insert(modifiedShow)
                }
                recentResponse.titles.forEach { show in
                    var modifiedShow = show
                    modifiedShow.uniqueId = "\(show.id)_\(Date().timeIntervalSince1970)"
                    allShows.insert(modifiedShow)
                }
                self.tvShows = Array(allShows).shuffled()
                self.hasMoreTVShows = popularResponse.page < popularResponse.totalPages
                self.currentTVShowPage = 2
            }
        } catch {
            handleError(error, type: type)
        }
        
        isLoading = false
    }
    
    func loadInitialContent(for type: MediaItem.MediaType) {
        Task { @MainActor in
            await refreshContent(for: type)
        }
    }
    
    private func loadAdditionalContent(for type: MediaItem.MediaType, currentSort: String) async throws {
        let differentSort = sortOptions.first(where: { $0 != currentSort }) ?? sortOptions[0]
        let additionalResponse = try await fetchContent(type: type, page: 1, sortBy: differentSort)
        
        if type == .movie {
            var allMovies = Set(movies)
            let newMovies = additionalResponse.titles.map { movie in
                var modifiedMovie = movie
                modifiedMovie.uniqueId = "\(movie.id)_\(Date().timeIntervalSince1970)_additional"
                return modifiedMovie
            }
            allMovies.formUnion(newMovies)
            movies = Array(allMovies).shuffled()
        } else {
            var allShows = Set(tvShows)
            let newShows = additionalResponse.titles.map { show in
                var modifiedShow = show
                modifiedShow.uniqueId = "\(show.id)_\(Date().timeIntervalSince1970)_additional"
                return modifiedShow
            }
            allShows.formUnion(newShows)
            tvShows = Array(allShows).shuffled()
        }
    }
    
    private func loadMoreContent(type: MediaItem.MediaType) {
        guard !isLoadingMore else { return }
        guard (type == .movie ? hasMoreMovies : hasMoreTVShows) else { return }
        
        Task { @MainActor in
            let currentPage = type == .movie ? currentMoviePage : currentTVShowPage
            isLoadingMore = true
            
            do {
                let response = try await fetchContent(type: type, page: currentPage, sortBy: "popularity_desc")
                
                if type == .movie {
                    let newMovies = response.titles.map { movie in
                        var modifiedMovie = movie
                        modifiedMovie.uniqueId = "\(movie.id)_\(Date().timeIntervalSince1970)"
                        return modifiedMovie
                    }
                    movies.append(contentsOf: newMovies)
                    hasMoreMovies = response.page < response.totalPages
                    currentMoviePage += 1
                } else {
                    let newShows = response.titles.map { show in
                        var modifiedShow = show
                        modifiedShow.uniqueId = "\(show.id)_\(Date().timeIntervalSince1970)"
                        return modifiedShow
                    }
                    tvShows.append(contentsOf: newShows)
                    hasMoreTVShows = response.page < response.totalPages
                    currentTVShowPage += 1
                }
            } catch {
                handleError(error, type: type)
            }
            
            isLoadingMore = false
        }
    }
    
    func loadMoreIfNeeded(currentItem item: MediaItem) {
        let items = item.type == .movie ? movies : tvShows
        let thresholdIndex = items.count - 5
        
        if let currentIndex = items.firstIndex(where: { $0.uniqueId == item.uniqueId }),
           currentIndex >= thresholdIndex {
            loadMoreContent(type: item.type)
        }
    }
    
    func retryLoad() {
        let type: MediaItem.MediaType = movies.isEmpty ? .movie : .tvShow
        loadInitialContent(for: type)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
} 
