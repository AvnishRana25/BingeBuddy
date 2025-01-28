import SwiftUI
@_exported import Combine
struct ContentView: View {
    @EnvironmentObject private var viewModel: MediaViewModel
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("BingeBuddy")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                HStack(spacing: 32) {
                    ForEach(["Movies", "TV Shows"].indices, id: \.self) { index in
                        VStack(spacing: 8) {
                            Text(index == 0 ? "Movies" : "TV Shows")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(selectedTab == index ? .bold : .medium)
                            
                
                            Capsule()
                                .fill(Color.accentColor)
                                .frame(height: 6)
                                .opacity(selectedTab == index ? 1 : 0)
                                .scaleEffect(selectedTab == index ? 1 : 0.5, anchor: .center)
                        }
                        .foregroundColor(selectedTab == index ? .primary : .secondary)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Color(colorScheme == .dark ? .systemGray6 : .systemBackground)
                        .shadow(color: Color(.systemGray4).opacity(0.15), radius: 8, y: 2)
                )
                
                let items = selectedTab == 0 ? viewModel.movies : viewModel.tvShows
                
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        if viewModel.isLoading && items.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in
                                ShimmerRowView()
                            }
                        } else if items.isEmpty && !viewModel.isLoading {
                            ContentUnavailableView {
                                Label("No Content Available", 
                                     systemImage: selectedTab == 0 ? "film.fill" : "tv.fill")
                                    .font(.system(.title2, design: .rounded))
                            } description: {
                                Text("Pull to refresh or try again later")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                            } actions: {
                                Button(action: {
                                    viewModel.loadInitialContent(for: selectedTab == 0 ? .movie : .tvShow)
                                }) {
                                    Text("Retry")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(width: 140)
                                        .padding(.vertical, 14)
                                        .background(Color.accentColor)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(items, id: \.uniqueId) { item in
                                NavigationLink(destination: DetailView(item: item)) {
                                    MediaItemRow(item: item)
                                        .task {
                                            viewModel.loadMoreIfNeeded(currentItem: item)
                                        }
                                }
                                .buttonStyle(ScaledButtonStyle())
                            }
                        
                            if viewModel.isLoadingMore {
                                VStack(spacing: 8) {
                                    LoadingIndicatorView()
                                    Text("Loading more content...")
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
                .background(Color(colorScheme == .dark ? .black : .systemBackground))
                .refreshable {
                    await viewModel.refreshContent(for: selectedTab == 0 ? .movie : .tvShow)
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .alert(viewModel.errorTitle, isPresented: $viewModel.showError) {
                if viewModel.errorAction == .retry {
                    Button("Retry") {
                        viewModel.retryLoad()
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            if viewModel.movies.isEmpty && viewModel.tvShows.isEmpty {
                viewModel.loadInitialContent(for: .movie)
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            let selectedType: MediaItem.MediaType = newValue == 0 ? .movie : .tvShow
            if (selectedType == .movie && viewModel.movies.isEmpty) ||
               (selectedType == .tvShow && viewModel.tvShows.isEmpty) {
                viewModel.loadInitialContent(for: selectedType)
            }
        }
        .navigationBarHidden(true)
    }
    
    @Namespace private var namespace
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environmentObject(MediaViewModel())
}

