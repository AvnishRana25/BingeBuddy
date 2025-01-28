import SwiftUI
@main
struct BingeBuddy: App {
    @StateObject private var viewModel = MediaViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
} 
