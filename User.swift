import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarColor: String
    var friendLevel: FriendLevel
    @Relationship(deleteRule: .cascade) var interests: [Interest] = []
    
    init(name: String, avatarColor: String, friendLevel: FriendLevel) {
        self.id = UUID()
        self.name = name
        self.avatarColor = avatarColor
        self.friendLevel = friendLevel
    }
}
