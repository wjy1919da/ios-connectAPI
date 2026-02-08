import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeLiveStatusView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ActivityHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            AIInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sparkles")
                }
        }
        .tint(Color.appBlue)
    }
}

#Preview {
    ContentView()
}
