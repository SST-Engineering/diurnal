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
    // For recurring tasks: ISO date strings ("YYYY-MM-DD") of days marked complete.
    // For non-recurring tasks this array is unused; isComplete/taskStatus are used instead.
    var completedDates: [String] = []

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

    // MARK: - Per-date status (used for recurring tasks)

    func effectiveStatus(for date: Date) -> String {
        guard !recurrenceRule.isEmpty else { return effectiveStatus }
        return completedDates.contains(isoDay(date)) ? "completed" : "notStarted"
    }

    func cycleStatus(for date: Date) {
        if recurrenceRule.isEmpty {
            switch effectiveStatus {
            case "notStarted": taskStatus = "started";   isComplete = false
            case "started":    taskStatus = "completed"; isComplete = true
            default:           taskStatus = "notStarted"; isComplete = false
            }
        } else {
            let key = isoDay(date)
            if completedDates.contains(key) {
                completedDates.removeAll { $0 == key }
            } else {
                completedDates.append(key)
            }
        }
    }

    private func isoDay(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
