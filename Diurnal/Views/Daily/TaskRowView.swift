import SwiftUI
import SwiftData

struct TaskRowView: View {
    @Bindable var task: DailyTask
    @Environment(\.modelContext) private var modelContext
    @State private var showDetail = false

    private var priorityColor: Color {
        switch task.priorityEnum {
        case .a: return .red
        case .b: return .orange
        case .c: return .blue
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Priority badge
            Text(task.label)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(priorityColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Rolled-over indicator
            if task.isRolledOver {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Title
            Text(task.title)
                .strikethrough(task.isComplete, color: .secondary)
                .foregroundStyle(task.isComplete ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { showDetail = true }

            // Complete toggle
            Button {
                task.isComplete.toggle()
            } label: {
                Image(systemName: task.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isComplete ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showDetail) {
            TaskDetailView(task: task)
        }
    }
}

struct TaskDetailView: View {
    @Bindable var task: DailyTask
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $task.title)
                    Picker("Priority", selection: $task.priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text("Priority \(p.rawValue)").tag(p.rawValue)
                        }
                    }
                    Stepper("Number: \(task.number)", value: $task.number, in: 1...99)
                }
                Section("Notes") {
                    TextEditor(text: $task.notes)
                        .frame(minHeight: 80)
                }
                if task.isRolledOver, let original = task.originalDate {
                    Section {
                        Label("Rolled over from \(original.formatted(.dateTime.weekday(.wide).day().month()))", systemImage: "arrow.turn.down.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Button("Delete Task", role: .destructive) {
                        modelContext.delete(task)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Task")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
