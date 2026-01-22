import Foundation
import SwiftData

@MainActor
class DataManager {
    static let shared = DataManager()
    
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                User.self,
                Activity.self,
                Interest.self,
                GroupSession.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    func seedDataIfNeeded(activityManager: ActivityManager) {
        let context = container.mainContext
        
        // Check User Count
        let descriptor = FetchDescriptor<User>()
        let userCount = (try? context.fetchCount(descriptor)) ?? 0
        
        if userCount == 0 {
            // Create Users
            // Me = Current User
            let me = User(name: "Me", avatarColor: "34C759", friendLevel: .innerCircle) // known Green
            
            // Alice = Inner Circle
            let friend1 = User(name: "Alice", avatarColor: "FF2D55", friendLevel: .innerCircle)
            
            // Bob = Crew
            let friend2 = User(name: "Bob", avatarColor: "FFCC00", friendLevel: .crew)
            
            // Charlie = Peers
            let friend3 = User(name: "Charlie", avatarColor: "34C759", friendLevel: .peers)
            
            context.insert(me)
            context.insert(friend1)
            context.insert(friend2)
            context.insert(friend3)
            
            activityManager.currentUser = me
            activityManager.allUsers = [me, friend1, friend2, friend3]
        } else {
             // Populate ActivityManager for subsequent runs
            let users = try? context.fetch(FetchDescriptor<User>())
            activityManager.allUsers = users ?? []
            activityManager.currentUser = users?.first(where: { $0.name == "Me" }) ?? users?.first
        }
        
        // Check Activity Count
        let activityDescriptor = FetchDescriptor<Activity>()
        let activityCount = (try? context.fetchCount(activityDescriptor)) ?? 0
        
        if activityCount < 10 {
            seedActivities(context: context)
        }
        
        try? context.save()
    }
    
    private func seedActivities(context: ModelContext) {
        let categoryColors: [String: String] = [
            "Sports": "FF9500",
            "Chill": "5856D6",
            "Arts": "AF52DE",
            "Games": "34C759",
            "Social": "007AFF"
        ]
        
        let activitiesData = [
            ("Biking", "bicycle", 2, "Sports"), ("Hiking", "figure.hiking", 2, "Sports"),
            ("Pickleball", "tennis.racket", 4, "Sports"), ("Basketball", "basketball.fill", 6, "Sports"),
            ("Soccer", "soccerball", 6, "Sports"), ("Rock Climbing", "figure.climbing", 2, "Sports"),
            ("Tennis", "tennisball.fill", 2, "Sports"), ("Kayaking", "figure.rower", 2, "Sports"),
            ("Run", "figure.run", 2, "Sports"), ("Bowling", "figure.bowling", 3, "Sports"),
            ("Volleyball", "volleyball.fill", 4, "Sports"), ("Golf", "figure.golf", 4, "Sports"),
            ("Frisbee Golf", "circle.dashed", 3, "Sports"), ("Kickball", "figure.kickboxing", 6, "Sports"),
            ("Ice Skating", "snowflake", 2, "Sports"), ("Archery", "target", 2, "Sports"),
            ("Paintball", "paintpalette.fill", 6, "Sports"), ("Swimming", "figure.pool.swim", 2, "Sports"),
            ("Workout", "dumbbell.fill", 2, "Sports"),
            
            ("Just Chill", "moon.stars.fill", 2, "Chill"), ("Yoga", "figure.yoga", 2, "Chill"),
            ("Painting Pottery", "paintpalette", 2, "Arts"), ("Museum", "building.columns.fill", 2, "Arts"),
            ("Film Festival", "film.fill", 2, "Arts"), ("Origami", "doc.plaintext.fill", 2, "Arts"),
            ("Theater", "theatermasks.fill", 2, "Arts"), ("Concert", "music.mic", 3, "Arts"),
            
            ("Chess", "crown.fill", 2, "Games"), ("Board Game", "dice.fill", 3, "Games"),
            ("Escape Room", "lock.open.fill", 4, "Games"), ("Video Games", "gamecontroller.fill", 2, "Games"),
            ("Poker", "suit.spade.fill", 4, "Games"), ("DND", "shield.fill", 4, "Games"),
            ("Esports Tourney", "trophy.fill", 5, "Games"), ("Mario Kart", "car.fill", 4, "Games"),
            
            ("Movies", "popcorn.fill", 2, "Social"), ("Mall", "bag.fill", 2, "Social"),
            ("Shopping", "cart.fill", 2, "Social"), ("Sporting Event", "sportscourt.fill", 3, "Social")
        ]
        
        for (name, icon, minParticipants, category) in activitiesData {
            context.insert(Activity(
                name: name,
                icon: icon,
                color: categoryColors[category] ?? "FFFFFF",
                minParticipants: minParticipants,
                x: .random(in: -300...300),
                y: .random(in: -600...600),
                z: .random(in: 100...5000),
                category: category
            ))
        }
    }
}
