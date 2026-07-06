import SwiftUI
import SwiftData

struct AddTaskView: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var existingTasks: [DailyTask]

    @State private var title = ""
    @State private var priority: TaskPriority = .a
    @State private var notes = ""
    @State private var recurrenceRule = ""
    @State private var recurrenceDays: [Int] = []
    @State private var hasEndDate = false
    @State private var recurrenceUntil = Date()

    private var nextNumber: Int {
        let samePriority = existingTasks.filter {
            Calendar.current.isDate($0.pageDate, inSameDayAs: date) &&
            $0.priority == priority.rawValue
        }
        return (samePriority.map(\.number).max() ?? 0) + 1
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                pageColor.ignoresSafeArea(.container, edges: .bottom)

                RuledLineShape()
                    .stroke(ruleColor, lineWidth: 0.5)
                    .allowsHitTesting(false)

                Rectangle()
                    .fill(marginColor)
                    .frame(width: 1)
                    .padding(.leading, 48)
                    .allowsHitTesting(false)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Header ──────────────────────────────────────
                        Text("New Task")
                            .font(.custom("Georgia", size: 26))
                            .foregroundStyle(inkColor)
                            .padding(.top, 28)
                            .padding(.horizontal, 56)

                        Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.custom("Georgia", size: 13))
                            .foregroundStyle(inkColor.opacity(0.45))
                            .italic()
                            .padding(.horizontal, 56)
                            .padding(.bottom, 10)

                        Divider().padding(.horizontal, 56).opacity(0.4)

                        // ── Task title ──────────────────────────────────
                        ParchmentFieldLabel(text: "Task Title")
                        TextField("", text: $title)
                            .font(.custom("Georgia", size: 16))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Priority ────────────────────────────────────
                        ParchmentFieldLabel(text: "Priority")
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            ParchmentPriorityRow(p: p, selected: priority) {
                                priority = p
                            }
                        }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Recurrence ──────────────────────────────────
                        ParchmentFieldLabel(text: "Repeat")
                        ParchmentRecurrencePicker(rule: $recurrenceRule)

                        if recurrenceRule == "weekly" {
                            ParchmentWeekdayPicker(selectedDays: $recurrenceDays)
                        }

                        if !recurrenceRule.isEmpty {
                            ParchmentEndDateRow(hasEndDate: $hasEndDate, endDate: $recurrenceUntil)
                        }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Notes ───────────────────────────────────────
                        ParchmentFieldLabel(text: "Notes (optional)")
                        TextEditor(text: $notes)
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: kLineSpacing * 3)
                            .padding(.horizontal, 52)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.custom("Georgia", size: 15))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .font(.custom("Georgia", size: 15).bold())
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let task = DailyTask(
            pageDate: date,
            priority: priority,
            number: nextNumber,
            title: title.trimmingCharacters(in: .whitespaces)
        )
        task.notes = notes
        task.recurrenceRule = recurrenceRule
        task.recurrenceDays = recurrenceRule == "weekly" ? recurrenceDays : []
        task.recurrenceUntil = hasEndDate ? recurrenceUntil : nil
        modelContext.insert(task)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Reusable parchment form components

struct ParchmentFieldLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 11))
            .foregroundStyle(inkColor.opacity(0.45))
            .textCase(.uppercase)
            .kerning(1.1)
            .padding(.horizontal, 56)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }
}

struct ParchmentPriorityRow: View {
    let p: TaskPriority
    let selected: TaskPriority
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Radio indicator
                ZStack {
                    Circle()
                        .stroke(p.diurnalColor.opacity(0.7), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                    if selected == p {
                        Circle()
                            .fill(p.diurnalColor)
                            .frame(width: 10, height: 10)
                    }
                }

                Text(p.rawValue)
                    .font(.custom("Georgia", size: 15).bold())
                    .foregroundStyle(p.diurnalColor)
                    .frame(width: 16, alignment: .leading)

                Text("— \(p.priorityDescription)")
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(inkColor.opacity(selected == p ? 0.85 : 0.50))

                Spacer()
            }
            .padding(.horizontal, 56)
            .frame(height: kLineSpacing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TaskPriority helpers

extension TaskPriority {
    var priorityDescription: String {
        switch self {
        case .a: return "Must do today"
        case .b: return "Should do today"
        case .c: return "Could do today"
        }
    }

    /// Consistent ink colours matching the day-page book rows
    var diurnalColor: Color {
        switch self {
        case .a: return Color(red: 0.75, green: 0.10, blue: 0.10)
        case .b: return Color(red: 0.70, green: 0.35, blue: 0.00)
        case .c: return Color(red: 0.15, green: 0.25, blue: 0.65)
        }
    }

    /// Legacy alias kept for any existing callers
    var swiftUIColor: Color { diurnalColor }
}
