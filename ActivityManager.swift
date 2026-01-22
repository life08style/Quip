import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class ActivityManager {
    var checkTimer: Timer?
    var currentUser: User?

    // Simulation helpers
    var allUsers: [User] = []
    
    // Debouncing
    private var debounceWorkItem: DispatchWorkItem?
    private var sessionCache: Set<String> = [] // Key: "ActivityID:SortedUserIDs"
    
    init() {
        // Start a timer to periodically simulate "activity" from others or check for matches
        // In a real app, this would be backend push notifications
    }
    

    
    func checkMatches(modelContext: ModelContext, specificActivity: Activity? = nil) {
        // Debounce rapid calls
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor in
                do {
                    // Only check specific activity if provided, otherwise check all
                    let activitiesToCheck: [Activity]
                    if let specific = specificActivity {
                        activitiesToCheck = [specific]
                    } else {
                        // Optimally, we should only fetch activities that have changed,
                        // but for now, we limit the fetch or rely on specificActivity triggering mostly.
                        let descriptor = FetchDescriptor<Activity>()
                        activitiesToCheck = try modelContext.fetch(descriptor)
                    }
                    
                    for activity in activitiesToCheck {
                        // Early exit if not enough participants
                        guard activity.interests.count >= activity.minParticipants else { continue }
                        
                        let participants = activity.interests
                            .sorted { ($0.user?.name ?? "") < ($1.user?.name ?? "") }
                            .compactMap { $0.user }
                        
                        // Create a robust cache key using UUIDs
                        let participantIds = participants.map { $0.id.uuidString }.joined(separator: ",")
                        let cacheKey = "\(activity.id.uuidString):\(participantIds)"
                        
                        // Check cache first to avoid database query
                        guard !self.sessionCache.contains(cacheKey) else { continue }
                        
                        // Check if session already exists
                        let sessionDescriptor = FetchDescriptor<GroupSession>()
                        let existingSessions = try modelContext.fetch(sessionDescriptor)
                        
                        // Double check against existing sessions in DB to be safe
                        let participantNames = participants.map { $0.name }.sorted()
                        let isDuplicate = existingSessions.contains { session in
                            session.activityName == activity.name && session.participants.sorted() == participantNames
                        }
                        
                        guard !isDuplicate else {
                            self.sessionCache.insert(cacheKey)
                            continue
                        }
                        
                        // Create session and clean up interests
                        modelContext.insert(GroupSession(activityName: activity.name, participants: participantNames))
                        activity.interests.forEach { modelContext.delete($0) }
                        
                        // Update cache
                        self.sessionCache.insert(cacheKey)
                        
                        // Notify/Feedback (Optional)
                        print("✅ Created Session for \(activity.name)")
                    }
                    
                    try modelContext.save()
                } catch {
                    print("⚠️ ActivityManager.checkMatches error: \(error.localizedDescription)")
                }
            }
        }
        
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func createSession(for activity: Activity, interests: [Interest], context: ModelContext) {
        // Deprecated - logic moved to checkMatches for efficiency
    }
    
    // MARK: - Simulation Logic
    func simulateFriendInterest(friend: User, activity: Activity, context: ModelContext) {
        // Toggle Logic
        if let existingInterest = activity.interests.first(where: { $0.user?.id == friend.id }) {
            context.delete(existingInterest)
            do {
                try context.save()
            } catch {
                print("⚠️ Failed to delete interest: \(error.localizedDescription)")
            }
            return
        }
        
        let newInterest = Interest(user: friend, activity: activity)
        context.insert(newInterest)
        
        do {
            try context.save()
            // Pass specific activity for optimized checking
            checkMatches(modelContext: context, specificActivity: activity)
        } catch {
            print("⚠️ Failed to save interest: \(error.localizedDescription)")
        }
    }
}
