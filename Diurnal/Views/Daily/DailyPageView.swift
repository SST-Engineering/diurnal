import SwiftUI
import SwiftData

// Design tokens are defined in Theme.swift

// MARK: - Ruled-line Shape (Swift 6 safe, no Canvas)

struct RuledLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 72
        while y < rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += kLineSpacing
        }
        return path
    }
}

// MARK: - DailyPageView

struct DailyPageView: View {
    @Binding var date: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Query private var allTasks: [DailyTask]
    @Query private var allAppointments: [Appointment]
    @Query private var allNotes: [DailyNote]

    @State private var showAddTask = false
    @State private var showAddAppointment = false
    @State private var iPhonePage = 0

    private var tasks: [DailyTask] {
        allTasks
            .filter { occursOn(date: date, pageDate: $0.pageDate, rule: $0.recurrenceRule) }
            .sorted { ($0.priority, $0.number) < ($1.priority, $1.number) }
    }

    private var appointments: [Appointment] {
        allAppointments
            .filter { occursOn(date: date, pageDate: $0.pageDate, rule: $0.recurrenceRule) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// True if an item with the given pageDate and recurrenceRule should appear on `date`.
    private func occursOn(date: Date, pageDate: Date, rule: String) -> Bool {
        let cal = Calendar.current
        let origin = cal.startOfDay(for: pageDate)
        let target = cal.startOfDay(for: date)
        if rule.isEmpty { return origin == target }
        guard target >= origin else { return false }
        switch rule {
        case "daily":   return true
        case "weekly":  return cal.component(.weekday, from: target) == cal.component(.weekday, from: origin)
        case "monthly": return cal.component(.day,     from: target) == cal.component(.day,     from: origin)
        case "yearly":
            return cal.component(.month, from: target) == cal.component(.month, from: origin) &&
                   cal.component(.day,   from: target) == cal.component(.day,   from: origin)
        default: return false
        }
    }

    private var dailyNote: DailyNote {
        if let n = allNotes.first(where: { Calendar.current.isDate($0.pageDate, inSameDayAs: date) }) { return n }
        let n = DailyNote(pageDate: date)
        modelContext.insert(n)
        return n
    }

    var body: some View {
        Group {
            if sizeClass == .compact {
                iPhoneLayout
            } else {
                bookLayout
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { showAddAppointment = true } label: {
                    Label("Add Appointment", systemImage: "calendar.badge.plus")
                }
                Button { showAddTask = true } label: {
                    Label("Add Task", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddTask)        { AddTaskView(date: date) }
        .sheet(isPresented: $showAddAppointment) { AddAppointmentView(date: date) }
    }

    // MARK: - Book layout (iPad / Mac)

    private var bookLayout: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.25))
                .blur(radius: 12)
                .padding(.horizontal, 8)
                .padding(.top, 12)

            HStack(spacing: 0) {
                LeftPageView(
                    date: $date,
                    tasks: tasks,
                    appointments: appointments,
                    allTasks: allTasks,
                    onRollover: rollover
                )
                .frame(maxWidth: .infinity)

                BookSpine()

                RightPageView(date: $date, note: dailyNote)
                    .frame(maxWidth: .infinity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(24)
    }

    // MARK: - iPhone layout

    private var iPhoneLayout: some View {
        VStack(spacing: 0) {
            Picker("", selection: $iPhonePage) {
                Text("Tasks").tag(0)
                Text("Notes").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(spineColor)

            if iPhonePage == 0 {
                LeftPageView(
                    date: $date,
                    tasks: tasks,
                    appointments: appointments,
                    allTasks: allTasks,
                    onRollover: rollover
                )
            } else {
                RightPageView(date: $date, note: dailyNote)
            }
        }
    }

    // MARK: - Rollover

    private func rollover(_ incomplete: [DailyTask]) {
        var counts: [String: Int] = [:]
        for t in tasks { counts[t.priority, default: 0] += 1 }
        for task in incomplete {
            let n = (counts[task.priority] ?? 0) + 1
            counts[task.priority] = n
            let rolled = DailyTask(pageDate: date, priority: task.priorityEnum, number: n, title: task.title)
            rolled.isRolledOver = true
            rolled.originalDate = task.pageDate
            rolled.notes = task.notes
            modelContext.insert(rolled)
        }
    }
}

// MARK: - Left page

struct LeftPageView: View {
    @Binding var date: Date
    let tasks: [DailyTask]
    let appointments: [Appointment]
    let allTasks: [DailyTask]
    let onRollover: ([DailyTask]) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
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
                    PageDateHeader(date: date)
                        .padding(.top, 20)
                        .padding(.horizontal, 56)
                        .padding(.bottom, 12)

                    Divider()
                        .padding(.horizontal, 56)
                        .opacity(0.4)

                    BookSectionHeader(title: "Appointments", icon: "clock")
                        .padding(.horizontal, 56)
                        .padding(.top, 14)

                    AppointmentTimeline(appointments: appointments)
                        .padding(.horizontal, 56)

                    BookSectionHeader(title: "Tasks", icon: "checklist")
                        .padding(.horizontal, 56)
                        .padding(.top, 14)

                    ForEach(TaskPriority.allCases, id: \.self) { p in
                        let group = tasks.filter { $0.priority == p.rawValue }
                        if !group.isEmpty {
                            BookPriorityLabel(priority: p)
                                .padding(.horizontal, 56)
                                .padding(.top, 6)
                            ForEach(group) { task in
                                BookTaskRow(task: task)
                                    .padding(.horizontal, 56)
                            }
                        }
                    }

                    if tasks.isEmpty {
                        BookEmptyRow(text: "No tasks — tap + to add one")
                            .padding(.horizontal, 56)
                    }

                    RolloverButton(
                        date: date,
                        allTasks: allTasks,
                        onRollover: onRollover
                    )
                    .padding(.horizontal, 56)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }

            // ← back arrow rendered ABOVE the ScrollView so it receives clicks
            VStack {
                HStack {
                    Button {
                        date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 30, weight: .thin))
                            .foregroundStyle(inkColor.opacity(0.75))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                Spacer()
            }
            .allowsHitTesting(true)
        }
    }
}

// MARK: - Right page

struct RightPageView: View {
    @Binding var date: Date
    let note: DailyNote
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack(alignment: .topLeading) {
            pageColor.ignoresSafeArea()

            RuledLineShape()
                .stroke(ruleColor, lineWidth: 0.5)
                .allowsHitTesting(false)

            Rectangle()
                .fill(marginColor)
                .frame(width: 1)
                .padding(.leading, 48)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                BookSectionHeader(title: "Notes", icon: "note.text")
                    .padding(.horizontal, 56)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                TextEditor(text: Bindable(note).content)
                    .font(.custom("Georgia", size: 15))
                    .foregroundStyle(inkColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .lineSpacing(kLineSpacing - 17)
                    .padding(.horizontal, 52)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onChange(of: note.content) { _, _ in
                        note.updatedAt = Date()
                        try? modelContext.save()
                    }
            }

            // → forward arrow rendered ABOVE the TextEditor so it receives clicks
            VStack {
                HStack {
                    Spacer()
                    Button {
                        date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 30, weight: .thin))
                            .foregroundStyle(inkColor.opacity(0.75))
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .allowsHitTesting(true)
        }
    }
}

// MARK: - Spine

struct BookSpine: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    spineColor.opacity(0.6),
                    spineColor,
                    spineColor.opacity(0.7),
                    spineColor.opacity(0.4),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            SpineStitchShape()
                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
        }
        .frame(width: 18)
        .shadow(color: .black.opacity(0.4), radius: 4)
    }
}

struct SpineStitchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let stitchWidth: CGFloat = 5
        let stitchHeight: CGFloat = 2
        let gap: CGFloat = 14
        let cx = rect.midX
        var y: CGFloat = 20
        while y < rect.height - 10 {
            let r = CGRect(x: cx - stitchWidth / 2, y: y, width: stitchWidth, height: stitchHeight)
            path.addRoundedRect(in: r, cornerSize: CGSize(width: 1, height: 1))
            y += gap
        }
        return path
    }
}

// MARK: - Date header (navigation handled by page corner arrows)

struct PageDateHeader: View {
    let date: Date

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .kerning(1.5)

            Text(date.formatted(.dateTime.day().month(.wide).year()))
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(inkColor)

            if Calendar.current.isDateInToday(date) {
                Text("Today")
                    .font(.custom("Georgia", size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }
}

// MARK: - Rollover button

struct RolloverButton: View {
    let date: Date
    let allTasks: [DailyTask]
    let onRollover: ([DailyTask]) -> Void

    private var incompletYesterday: [DailyTask] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
        return allTasks.filter {
            Calendar.current.isDate($0.pageDate, inSameDayAs: yesterday) && !$0.isComplete
        }
    }

    var body: some View {
        if !incompletYesterday.isEmpty {
            Button {
                onRollover(incompletYesterday)
            } label: {
                Label(
                    "Roll over \(incompletYesterday.count) task(s) from yesterday",
                    systemImage: "arrow.turn.down.right"
                )
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Book row components

struct BookSectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        Label(title, systemImage: icon)
            .font(.custom("Georgia", size: 12))
            .foregroundStyle(inkColor.opacity(0.55))
            .textCase(.uppercase)
            .kerning(1.2)
            .padding(.bottom, 2)
    }
}

struct BookEmptyRow: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Georgia", size: 13))
            .foregroundStyle(inkColor.opacity(0.30))
            .italic()
            .frame(height: kLineSpacing)
    }
}

struct BookPriorityLabel: View {
    let priority: TaskPriority
    private var color: Color {
        switch priority {
        case .a: return Color(red: 0.75, green: 0.10, blue: 0.10)
        case .b: return Color(red: 0.70, green: 0.35, blue: 0.00)
        case .c: return Color(red: 0.15, green: 0.25, blue: 0.65)
        }
    }
    var body: some View {
        Text("Priority \(priority.rawValue)")
            .font(.custom("Georgia", size: 11))
            .foregroundStyle(color)
            .textCase(.uppercase)
            .kerning(1.0)
    }
}

struct BookTaskRow: View {
    @Bindable var task: DailyTask
    @Environment(\.modelContext) private var modelContext
    @State private var showDetail = false
    @State private var showMoveDate = false
    @State private var moveToDate = Date()

    private var status: String { task.effectiveStatus }

    private var priorityColor: Color {
        switch task.priorityEnum {
        case .a: return Color(red: 0.75, green: 0.10, blue: 0.10)
        case .b: return Color(red: 0.70, green: 0.35, blue: 0.00)
        case .c: return Color(red: 0.15, green: 0.25, blue: 0.65)
        }
    }

    /// Tap the status icon to cycle: not started → started → completed → not started
    private func cycleStatus() {
        switch status {
        case "notStarted":
            task.taskStatus = "started";   task.isComplete = false
        case "started":
            task.taskStatus = "completed"; task.isComplete = true
        default:
            task.taskStatus = "notStarted"; task.isComplete = false
        }
        try? modelContext.save()
    }

    var body: some View {
        HStack(spacing: 10) {
            // Status icon — tap to cycle
            Button { cycleStatus() } label: {
                Group {
                    switch status {
                    case "completed":
                        Image(systemName: "checkmark.square.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(red: 0.15, green: 0.52, blue: 0.25))
                    case "started":
                        Circle()
                            .fill(priorityColor)
                            .frame(width: 8, height: 8)
                            .frame(width: 13, height: 13) // match tap area
                    default:
                        Image(systemName: "square")
                            .font(.system(size: 13))
                            .foregroundStyle(priorityColor.opacity(0.45))
                    }
                }
            }
            .buttonStyle(.plain)

            Text(task.label)
                .font(.custom("Georgia", size: 11).bold())
                .foregroundStyle(priorityColor)
                .frame(width: 22, alignment: .leading)

            if task.isRolledOver {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 9))
                    .foregroundStyle(inkColor.opacity(0.35))
            }

            // Title — tap to open detail; hover (macOS) or long-press when not started → move date
            Text(task.title)
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(status == "completed" ? inkColor.opacity(0.4) : inkColor)
                .strikethrough(status == "completed", color: inkColor.opacity(0.4))
                .italic(status == "started")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { showDetail = true }
                .onHover { hovering in
                    if hovering && status == "notStarted" {
                        moveToDate = task.pageDate
                        showMoveDate = true
                    }
                }
                .onLongPressGesture {
                    if status == "notStarted" {
                        moveToDate = task.pageDate
                        showMoveDate = true
                    }
                }
                .popover(isPresented: $showMoveDate) {
                    MoveDatePopover(task: task, moveToDate: $moveToDate, isPresented: $showMoveDate)
                }
        }
        .frame(height: kLineSpacing)
        .sheet(isPresented: $showDetail) { TaskDetailView(task: task) }
    }
}

// MARK: - Move-date popover

struct MoveDatePopover: View {
    @Bindable var task: DailyTask
    @Binding var moveToDate: Date
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Move to date")
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(inkColor.opacity(0.55))
                .textCase(.uppercase)
                .kerning(1.1)

            DatePicker("", selection: $moveToDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(spineColor)
                .environment(\.colorScheme, .light)  // ensure dates are legible on parchment

            Button {
                task.pageDate = Calendar.current.startOfDay(for: moveToDate)
                try? modelContext.save()
                isPresented = false
            } label: {
                Text("Move Task")
                    .font(.custom("Georgia", size: 14))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(spineColor)
        }
        .padding(20)
        .background(pageColor)
        .frame(minWidth: 300)
    }
}

struct BookAppointmentRow: View {
    @Bindable var appointment: Appointment
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 10) {
            Text(appointment.startTime.formatted(.dateTime.hour().minute()))
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(inkColor.opacity(0.50))
                .frame(width: 44, alignment: .trailing)
                .monospacedDigit()

            Rectangle()
                .fill(Color(red: 0.25, green: 0.40, blue: 0.65))
                .frame(width: 2, height: 14)
                .clipShape(Capsule())

            Text(appointment.title)
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(inkColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { showDetail = true }
        }
        .frame(height: kLineSpacing)
        .sheet(isPresented: $showDetail) { AppointmentDetailView(appointment: appointment) }
    }
}
