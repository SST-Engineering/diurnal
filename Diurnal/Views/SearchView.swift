import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allTasks: [DailyTask]
    @Query private var allAppointments: [Appointment]
    @Query private var allNotes: [DailyNote]

    @Binding var selectedDate: Date
    @State private var query = ""

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }

    private var matchingTasks: [DailyTask] {
        guard !trimmed.isEmpty else { return [] }
        return allTasks
            .filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.pageDate > $1.pageDate }
    }

    private var matchingAppointments: [Appointment] {
        guard !trimmed.isEmpty else { return [] }
        return allAppointments
            .filter {
                $0.title.localizedCaseInsensitiveContains(trimmed) ||
                $0.location.localizedCaseInsensitiveContains(trimmed) ||
                $0.notes.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { $0.pageDate > $1.pageDate }
    }

    private var matchingNotes: [DailyNote] {
        guard !trimmed.isEmpty else { return [] }
        return allNotes
            .filter { !$0.content.isEmpty && $0.content.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.pageDate > $1.pageDate }
    }

    private var hasResults: Bool {
        !matchingTasks.isEmpty || !matchingAppointments.isEmpty || !matchingNotes.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                pageColor.ignoresSafeArea()

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
                        if trimmed.isEmpty {
                            emptyPrompt
                        } else if !hasResults {
                            noResults
                        } else {
                            resultsList
                        }
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 12)
                }
            }
            .searchable(text: $query, prompt: "Search tasks, appointments & notes…")
            .navigationTitle("Search")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.custom("Georgia", size: 15))
                }
            }
        }
    }

    // MARK: - Empty / no-results states

    private var emptyPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(inkColor.opacity(0.18))
            Text("Search your diary")
                .font(.custom("Georgia", size: 16))
                .foregroundStyle(inkColor.opacity(0.35))
                .italic()
            Text("Tasks, appointments and notes")
                .font(.custom("Georgia", size: 13))
                .foregroundStyle(inkColor.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var noResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(inkColor.opacity(0.18))
            Text("Nothing found for \"\(trimmed)\"")
                .font(.custom("Georgia", size: 15))
                .foregroundStyle(inkColor.opacity(0.35))
                .italic()
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsList: some View {
        if !matchingTasks.isEmpty {
            SearchSectionHeader(title: "Tasks", icon: "checklist", count: matchingTasks.count)
            ForEach(matchingTasks) { task in
                TaskResultRow(task: task, query: trimmed) {
                    selectedDate = Calendar.current.startOfDay(for: task.pageDate)
                    dismiss()
                }
            }
        }

        if !matchingAppointments.isEmpty {
            SearchSectionHeader(title: "Appointments", icon: "clock", count: matchingAppointments.count)
            ForEach(matchingAppointments) { appt in
                AppointmentResultRow(appointment: appt, query: trimmed) {
                    selectedDate = Calendar.current.startOfDay(for: appt.pageDate)
                    dismiss()
                }
            }
        }

        if !matchingNotes.isEmpty {
            SearchSectionHeader(title: "Notes", icon: "note.text", count: matchingNotes.count)
            ForEach(matchingNotes) { note in
                NoteResultRow(note: note, query: trimmed) {
                    selectedDate = Calendar.current.startOfDay(for: note.pageDate)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Section header

private struct SearchSectionHeader: View {
    let title: String
    let icon: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Label(title, systemImage: icon)
            Spacer()
            Text("\(count)")
                .monospacedDigit()
        }
        .font(.custom("Georgia", size: 11))
        .foregroundStyle(inkColor.opacity(0.45))
        .textCase(.uppercase)
        .kerning(1.2)
        .padding(.horizontal, 56)
        .padding(.top, 24)
        .padding(.bottom, 4)
    }
}

// MARK: - Task result row

private struct TaskResultRow: View {
    let task: DailyTask
    let query: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: task.isComplete ? "checkmark.square" : "square")
                    .font(.system(size: 12))
                    .foregroundStyle(inkColor.opacity(0.45))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    HighlightedText(text: task.title, highlight: query)
                        .font(.custom("Georgia", size: 14))
                        .strikethrough(task.isComplete, color: inkColor.opacity(0.4))

                    Text(task.pageDate.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(inkColor.opacity(0.40))
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(task.label)
                    .font(.custom("Georgia", size: 11).bold())
                    .foregroundStyle(inkColor.opacity(0.35))
            }
            .padding(.horizontal, 56)
            .frame(height: kLineSpacing)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Appointment result row

private struct AppointmentResultRow: View {
    let appointment: Appointment
    let query: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(inkColor.opacity(0.45))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    HighlightedText(text: appointment.title, highlight: query)
                        .font(.custom("Georgia", size: 14))

                    HStack(spacing: 4) {
                        Text(appointment.pageDate.formatted(.dateTime.day().month(.abbreviated).year()))
                        Text("·")
                        Text(appointment.startTime.formatted(.dateTime.hour().minute()))
                    }
                    .font(.custom("Georgia", size: 11))
                    .foregroundStyle(inkColor.opacity(0.40))
                    .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 56)
            .frame(height: kLineSpacing)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Note result row

private struct NoteResultRow: View {
    let note: DailyNote
    let query: String
    let onTap: () -> Void

    /// Return a short excerpt around the first match
    private var excerpt: String {
        let content = note.content
        guard let range = content.range(of: query, options: .caseInsensitive) else {
            return String(content.prefix(80))
        }
        let start = content.index(range.lowerBound, offsetBy: -30, limitedBy: content.startIndex) ?? content.startIndex
        let end   = content.index(range.upperBound, offsetBy: 50, limitedBy: content.endIndex) ?? content.endIndex
        let snip  = String(content[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (start > content.startIndex ? "…" : "") + snip + (end < content.endIndex ? "…" : "")
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: 12))
                    .foregroundStyle(inkColor.opacity(0.45))
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 1) {
                    Text(note.pageDate.formatted(.dateTime.day().month(.wide).year()))
                        .font(.custom("Georgia", size: 14))
                        .foregroundStyle(inkColor)

                    HighlightedText(text: excerpt, highlight: query)
                        .font(.custom("Georgia", size: 12))
                        .italic()
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 56)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Highlighted text helper

/// Renders text, bolding any substrings that match the search query.
private struct HighlightedText: View {
    let text: String
    let highlight: String

    var body: some View {
        segments.reduce(Text("")) { acc, seg in
            acc + (seg.isMatch
                ? Text(seg.value).bold().foregroundStyle(inkColor)
                : Text(seg.value).foregroundStyle(inkColor.opacity(0.5)))
        }
    }

    private struct Segment { let value: String; let isMatch: Bool }

    private var segments: [Segment] {
        var result: [Segment] = []
        var remaining = text
        while !remaining.isEmpty {
            if let range = remaining.range(of: highlight, options: .caseInsensitive) {
                let before = String(remaining[remaining.startIndex..<range.lowerBound])
                if !before.isEmpty { result.append(Segment(value: before, isMatch: false)) }
                result.append(Segment(value: String(remaining[range]), isMatch: true))
                remaining = String(remaining[range.upperBound...])
            } else {
                result.append(Segment(value: remaining, isMatch: false))
                break
            }
        }
        return result
    }
}
