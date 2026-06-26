import SwiftData
import Foundation

@Model
final class WeeklyCompass {
    var id: UUID
    var weekStart: Date           // always a Monday
    var weeklyGoals: String       // newline-separated goals for the week
    var physicalRenewal: String   // sharpening the saw — body
    var socialRenewal: String     // sharpening the saw — relationships
    var mentalRenewal: String     // sharpening the saw — mind
    var spiritualRenewal: String  // sharpening the saw — spirit
    var notes: String
    var updatedAt: Date

    init(weekStart: Date) {
        self.id = UUID()
        self.weekStart = Self.monday(for: weekStart)
        self.weeklyGoals = ""
        self.physicalRenewal = ""
        self.socialRenewal = ""
        self.mentalRenewal = ""
        self.spiritualRenewal = ""
        self.notes = ""
        self.updatedAt = Date()
    }

    static func monday(for date: Date) -> Date {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        // weekday: 1=Sun, 2=Mon ... 7=Sat
        let daysToMonday = (weekday == 1) ? -6 : 2 - weekday
        return cal.startOfDay(for: cal.date(byAdding: .day, value: daysToMonday, to: date)!)
    }

    var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
    }
}
