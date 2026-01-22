import Foundation
import SwiftData

@Model
final class Activity {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var color: String
    var minParticipants: Int
    var x: Double
    var y: Double
    var z: Double
    var category: String
    @Relationship(deleteRule: .cascade) var interests: [Interest] = []
    
    init(name: String, icon: String, color: String, minParticipants: Int, x: Double, y: Double, z: Double, category: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.minParticipants = minParticipants
        self.x = x
        self.y = y
        self.z = z
        self.category = category
    }
}
