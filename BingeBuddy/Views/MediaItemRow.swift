import SwiftUI
import Kingfisher
struct MediaItemRow: View {
    let item: MediaItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: item.type == .movie ? "film" : "tv")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    if let releaseDate = item.formattedReleaseDate {
                        Text(releaseDate)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                MediaTypeBadge(type: item.type)
                    .padding(.top, 4)
            }
            
            if let description = item.description {
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .padding(.top, 4)
                    .padding(.leading, 40)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(colorScheme == .dark ? .systemGray6 : .systemBackground))
                .shadow(
                    color: Color(.systemGray4).opacity(colorScheme == .dark ? 0.1 : 0.15),
                    radius: 10,
                    x: 0,
                    y: 2
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct PosterImageView: View {
    let url: String?
    let type: MediaItem.MediaType
    
    var body: some View {
        Group {
            if let posterURL = URL(string: url ?? "") {
                KFImage.url(posterURL)
                    .resizable()
                    .placeholder {
                        PlaceholderView(type: type)
                    }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 85, height: 128)))
                    .cacheOriginalImage()
                    .fade(duration: 0.25)
                    .aspectRatio(contentMode: .fill)
            } else {
                PlaceholderView(type: type)
            }
        }
    }
}

struct PlaceholderView: View {
    let type: MediaItem.MediaType
    
    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: type == .movie ? "film.fill" : "tv.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            )
    }
}

struct MediaTypeBadge: View {
    let type: MediaItem.MediaType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text(type == .movie ? "Movie" : "TV Show")
            .font(.system(.subheadline, design: .rounded))
            .fontWeight(.medium)
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? 
                          Color.accentColor.opacity(0.2) : 
                          Color.accentColor.opacity(0.1))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

//Only for personal preview
#Preview {
    MediaItemRow(item: MediaItem(
        id: 1,
        title: "Sample Movie",
        description: "A sample description",
        posterURL: "https://cdn.watchmode.com/posters/01543519_poster_w185.jpg",
        releaseDate: "2024-03-15",
        type: .movie,
        year: 2024
    ))
} 
