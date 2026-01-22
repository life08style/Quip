import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityManager.self) private var activityManager
    
    var body: some View {
        TabView {
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "globe")
                }
            
            PlannedActivitiesView()
                .tabItem {
                    Label("Planned", systemImage: "calendar")
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [User.self, Activity.self, Interest.self, GroupSession.self], inMemory: true)
        .environment(ActivityManager())
}
