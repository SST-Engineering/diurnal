import SwiftData
import Foundation

@Model
final class MissionStatement {
    var id: UUID
    var content: String
    var updatedAt: Date

    init() {
        self.id = UUID()
        self.content = ""
        self.updatedAt = Date()
    }
}
