import SwiftUI
import Kingfisher
import Combine
struct DetailView: View {
    let item: MediaItem
    @State private var detailedItem: MediaItem?
    @State private var isLoading = true
    @State private var error: APIError?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    private let api = WatchmodeAPI()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let displayItem = detailedItem ?? item
                
                ZStack(alignment: .top) {
                    if let posterURL = URL(string: displayItem.fullPosterURL ?? ""),
                       !posterURL.absoluteString.isEmpty {
                        KFImage(posterURL)
                            .resizable()
                            .placeholder {
                                Rectangle()
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        ProgressView()
                                            .tint(.gray)
                                    )
                            }
                            .aspectRatio(2/3, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: 450)
                            .background(Color(.systemGray6))
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .black.opacity(0.7),
                                        .black.opacity(0.3),
                                        .clear,
                                        colorScheme == .dark ? .black : .white
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 450)
                            .overlay(
                                VStack(spacing: 12) {
                                    Image(systemName: displayItem.type == .movie ? "film.fill" : "tv.fill")
                                        .font(.system(size: 50))
                                    Text("No Poster Available")
                                        .font(.caption)
                                }
                                .foregroundColor(.gray)
                            )
                    }
                    
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.black.opacity(0.5))
                                        .overlay(
                                            Capsule()
                                                .stroke(.white.opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                )
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(displayItem.title)
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            if let formattedDate = displayItem.formattedReleaseDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                    Text(formattedDate)
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    
                    if let description = displayItem.description {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Overview")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            
                            Text(description)
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(24)
                .background(Color(colorScheme == .dark ? .black : .systemBackground))
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarHidden(true)
        .onAppear {
            loadDetails()
        }
    }
    
    private func loadDetails() {
        isLoading = true
        
        api.fetchTitleDetails(id: item.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let apiError) = completion {
                        error = apiError
                    }
                },
                receiveValue: { detailedItem in
                    self.detailedItem = detailedItem
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview {
    DetailView(item: MediaItem(
        id: 1,
        title: "Hera Pheri",
        description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua",
        posterURL: "https://image.tmdb.org/t/p/original/jSnwHZTkSufd5rFenTm2jUP03wV.jpg",
        releaseDate: "2024-03-15",
        type: .movie,
        year: 2024
    ))
} 
