import SwiftUI
import SwiftData

struct PlannedActivitiesView: View {
    @Environment(ActivityManager.self) private var activityManager
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \GroupSession.createdAt, order: .reverse) private var sessions: [GroupSession]
    @Query private var activities: [Activity]
    
    // Cached filtered activities to prevent recalculation on every render
    @State private var myActivities: [Activity] = []
    @State private var networkActivities: [Activity] = []
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // 1. Group Chats Section
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Group Chats")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            ForEach(sessions) { session in
                                NavigationLink(destination: SessionDetailView(session: session)) {
                                    SessionRowCard(session: session)
                                }
                            }
                        }
                    }
                    
                    // 2. My Activities Section
                    if !myActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Activities")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            ForEach(myActivities) { activity in
                                MyActivityRow(activity: activity, currentUser: activityManager.currentUser)
                            }
                        }
                    }
                    
                    // 3. Network Activities Section
                    if !networkActivities.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Network")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            ForEach(networkActivities) { activity in
                                NetworkActivityRow(
                                    activity: activity, 
                                    currentUser: activityManager.currentUser,
                                    toggleAction: { toggleInterest(for: activity) }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Planned Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                updateFilteredActivities()
            }
            .onChange(of: activities) { _, _ in
                updateFilteredActivities()
            }
            .onChange(of: activityManager.currentUser) { _, _ in
                updateFilteredActivities()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Update Methods
    
    @MainActor
    private func updateFilteredActivities() {
        guard let user = activityManager.currentUser else {
            myActivities = []
            networkActivities = []
            return
        }
        
        // Build index for faster lookups
        let userInterestActivityIds = Set(user.interests.compactMap { $0.activity?.id })
        
        myActivities = activities.filter { userInterestActivityIds.contains($0.id) }
        
        networkActivities = activities.filter { activity in
            !userInterestActivityIds.contains(activity.id) && !activity.interests.isEmpty
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func toggleInterest(for activity: Activity) {
        guard let user = activityManager.currentUser else {
            showErrorAlert("No user logged in")
            return
        }
        
        if let interest = activity.interests.first(where: { $0.user?.id == user.id }) {
            modelContext.delete(interest)
        } else {
            let interest = Interest(user: user, activity: activity)
            modelContext.insert(interest)
        }
        
        do {
            try modelContext.save()
            activityManager.checkMatches(modelContext: modelContext, specificActivity: activity)
        } catch {
            showErrorAlert("Failed to save: \(error.localizedDescription)")
        }
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Subviews

struct SessionRowCard: View {
    let session: GroupSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.activityName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(session.scheduledTime.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding()
        .background(Color(hex: "2a1a40"))
        .cornerRadius(12)
    }
}

struct MyActivityRow: View {
    let activity: Activity
    let currentUser: User?
    
    var progress: Double {
        let count = Double(activity.interests.count)
        let total = Double(activity.minParticipants)
        return min(count / total, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(activity.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("\(activity.interests.count)/\(activity.minParticipants)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color(hex: activity.color))
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("You are down for this")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct NetworkActivityRow: View {
    let activity: Activity
    let currentUser: User?
    let toggleAction: () -> Void
    
    var interestedFriends: [User] {
        activity.interests.compactMap { $0.user }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(activity.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                HStack(spacing: -8) {
                    ForEach(interestedFriends.prefix(5)) { user in
                        Circle()
                            .fill(Color(hex: user.avatarColor))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(Color.black, lineWidth: 2)
                            )
                    }
                    if interestedFriends.count > 5 {
                        Text("+\(interestedFriends.count - 5)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.leading, 12)
                    }
                }
                
                Text(friendLevelSummaries)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: toggleAction) {
                Text("Join")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    var friendLevelSummaries: String {
        // Group users by friend level
        let counts = interestedFriends.reduce(into: [FriendLevel: Int]()) { result, user in
            result[user.friendLevel, default: 0] += 1
        }
        
        var parts: [String] = []
        if let core = counts[.innerCircle], core > 0 { parts.append("\(core) Core") }
        if let circle = counts[.crew], circle > 0 { parts.append("\(circle) Circle") }
        if let club = counts[.peers], club > 0 { parts.append("\(club) Club") }
        
        return parts.joined(separator: ", ")
    }
}
