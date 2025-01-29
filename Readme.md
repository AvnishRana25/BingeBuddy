# 🍿 BingeBuddy - Movie & TV Show Discovery App

BingeBuddy is an iOS app built with **SwiftUI** that helps users discover movies and TV shows by fetching data from the **Watchmode API**. Designed with simplicity in mind, it offers a seamless experience for browsing trending and popular content.

---

## ✨ Features

- **Discover Trending & Popular Content**:  
  View curated lists of trending movies and popular TV shows on the home screen.
- **Detailed Information**:  
  Tap any title to see details like genre, runtime, ratings, and a brief synopsis.
- **Simultaneous API Calls**:  
  Uses `Publishers.zip` to fetch multiple datasets (e.g., movies and shows) in parallel for faster loading.
- **Basic Testing**:  
  Unit tests for core components using mock API responses.

---

## 🛠 Tech Stack

- **SwiftUI** for declarative UI design.
- **Combine** for reactive data handling (e.g., `Publishers.zip`).
- **Watchmode API** for fetching movie/TV show data.
- **Xcode** for development and testing.
- **KingFisher** for Image loading and Caching.

---

## 🔧 Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/[your-username]/BingeBuddy.git
   ```

2. **Open in Xcode**:
   Launch `BingeBuddy.xcodeproj` in Xcode 15+.
3. **Add Watchmode API Key**:
   - Get an API key from [Watchmode](https://api.watchmode.com/).
   - Add it to `Services/WatchmodeAPI.swift` under `API KEY HERE`.
4. **Build & Run**:
   Target iOS 17+ and run on a simulator or device.

---

## 🎯 Challenges & Learnings

### 🚧 Challenges

- **Watchmode API Integration**:
  Some endpoints required trial-and-error to parse responses correctly.
- **Concurrent API Calls**:
  Implemented `Publishers.zip` to combine multiple API requests (e.g., fetching movies and shows at once).
- **Testing**:
  Mocking API responses for reliable unit tests.

### 📚 Learnings

- Improved proficiency in SwiftUI and Combine.
- Gained experience with reactive data pipelines.
- Learned to structure scalable network layers.

---

## 🔮 Future Improvements

- **Enhanced UI/UX**:
  Add custom animations, better grids, and dark mode support.
- **Backend Optimization**:
  Implement caching for faster load times and reduce API calls.
- **New Features**:
  - User accounts with favorites/watchlists.
  - Trailers and reviews section.
  - Pagination for infinite scrolling.
- **Expanded Testing**:
  Add UI tests and improve test coverage.
- **Search Functionality**:
  Add UI tests and improve test coverage.

---

## ⚠️ Assumptions

- Requires **Xcode 15+** and **iOS 17+**.
- A valid Watchmode API key is needed (free tier works).
- Network connectivity is assumed for API calls.

---
