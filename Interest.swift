import Foundation
import SwiftData

@Model
final class Interest {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    
    @Relationship(inverse: \User.interests) var user: User?
    @Relationship(inverse: \Activity.interests) var activity: Activity?
    
    init(user: User, activity: Activity) {
        self.id = UUID()
        self.createdAt = Date()
        self.user = user
        self.activity = activity
    }
}
