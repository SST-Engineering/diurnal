import SwiftData
import Foundation

@Model
final class DailyNote {
    var id: UUID
    var pageDate: Date
    var content: String
    var updatedAt: Date

    init(pageDate: Date) {
        self.id = UUID()
        self.pageDate = Calendar.current.startOfDay(for: pageDate)
        self.content = ""
        self.updatedAt = Date()
    }
}
