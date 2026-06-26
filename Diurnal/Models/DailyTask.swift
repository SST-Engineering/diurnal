import SwiftData
import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"

    var label: String { rawValue }
    var color: String {
        switch self {
        case .a: return "red"
        case .b: return "orange"
        case .c: return "blue"
        }
    }
}

@Model
final class DailyTask {
    var id: UUID
    var pageDate: Date
    var priority: String          // "A", "B", "C"
    var number: Int
    var title: String
    var isComplete: Bool
    var taskStatus: String = "notStarted"   // "notStarted", "started", "completed"
    var isRolledOver: Bool
    var originalDate: Date?
    var notes: String
    var createdAt: Date
    // "" = no recurrence | "daily" | "weekly" | "monthly" | "yearly"
    var recurrenceRule: String = ""

    init(pageDate: Date, priority: TaskPriority, number: Int, title: String) {
        self.id = UUID()
        self.pageDate = Calendar.current.startOfDay(for: pageDate)
        self.priority = priority.rawValue
        self.number = number
        self.title = title
        self.isComplete = false
        self.taskStatus = "notStarted"
        self.isRolledOver = false
        self.notes = ""
        self.createdAt = Date()
    }

    var priorityEnum: TaskPriority {
        TaskPriority(rawValue: priority) ?? .c
    }

    var label: String { "\(priority)\(number)" }

    /// Resolves status, handling legacy records that only have isComplete set.
    var effectiveStatus: String {
        if isComplete && taskStatus == "notStarted" { return "completed" }
        return taskStatus
    }
}
