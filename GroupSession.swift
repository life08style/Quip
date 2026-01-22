import Foundation
import SwiftData

@Model
final class GroupSession {
    @Attribute(.unique) var id: UUID
    var activityName: String
    var participants: [String]
    var scheduledTime: Date
    var createdAt: Date
    var location1: String
    var location2: String
    var bookingLink1: String
    var bookingLink2: String
    
    init(activityName: String, participants: [String]) {
        self.id = UUID()
        self.activityName = activityName
        self.participants = participants
        
        // Set scheduled time to 2 hours from now as default
        self.scheduledTime = Date().addingTimeInterval(2 * 60 * 60)
        self.createdAt = Date()
        
        // Generate placeholder locations and booking links
        self.location1 = "Central Park"
        self.location2 = "Downtown Recreation Center"
        self.bookingLink1 = "https://example.com/book/location1"
        self.bookingLink2 = "https://example.com/book/location2"
    }
}
