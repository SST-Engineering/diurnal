import SwiftData
import Foundation

enum GoalTimeframe: String, Codable, CaseIterable {
    case longRange  = "Long Range"      // lifetime / 5+ years
    case intermediate = "Intermediate"  // 1–5 years
    case shortRange = "Short Range"     // this year / this month

    var icon: String {
        switch self {
        case .longRange: return "mountain.2"
        case .intermediate: return "flag"
        case .shortRange: return "checkmark.circle"
        }
    }
}

@Model
final class Goal {
    var id: UUID
    var title: String
    var timeframe: String
    var targetDate: Date?
    var progressNotes: String
    var isComplete: Bool
    var createdAt: Date
    var completedAt: Date?

    init(title: String, timeframe: GoalTimeframe) {
        self.id = UUID()
        self.title = title
        self.timeframe = timeframe.rawValue
        self.progressNotes = ""
        self.isComplete = false
        self.createdAt = Date()
    }

    var timeframeEnum: GoalTimeframe {
        GoalTimeframe(rawValue: timeframe) ?? .shortRange
    }
}
