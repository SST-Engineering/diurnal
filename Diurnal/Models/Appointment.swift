import SwiftData
import Foundation

@Model
final class Appointment {
    var id: UUID
    var pageDate: Date
    var startTime: Date
    var endTime: Date
    var title: String
    var location: String
    var notes: String
    var createdAt: Date
    var isAllDay: Bool = false
    // "" = no recurrence | "daily" | "weekly" | "monthly" | "yearly"
    var recurrenceRule: String = ""
    // For weekly recurrence: Calendar weekday ints (1=Sun…7=Sat). Empty = use origin weekday.
    var recurrenceDays: [Int] = []
    // Optional stop date — recurrence ends on or before this day.
    var recurrenceUntil: Date? = nil

    init(pageDate: Date, startTime: Date, endTime: Date, title: String) {
        self.id = UUID()
        self.pageDate = Calendar.current.startOfDay(for: pageDate)
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.location = ""
        self.notes = ""
        self.createdAt = Date()
    }

    var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}
