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
    @State private var confirmDelete = false

    private func save() { try? modelContext.save() }

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

                        Text("Edit Task")
                            .font(.custom("Georgia", size: 26))
                            .foregroundStyle(inkColor)
                            .padding(.top, 28)
                            .padding(.horizontal, 56)

                        Text(task.pageDate.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.custom("Georgia", size: 13))
                            .foregroundStyle(inkColor.opacity(0.45))
                            .italic()
                            .padding(.horizontal, 56)
                            .padding(.bottom, 10)

                        Divider().padding(.horizontal, 56).opacity(0.4)

                        ParchmentFieldLabel(text: "Title")
                        TextField("", text: $task.title)
                            .font(.custom("Georgia", size: 16))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)
                            .onChange(of: task.title) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        ParchmentFieldLabel(text: "Priority")
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            ParchmentPriorityRow(p: p, selected: task.priorityEnum) {
                                task.priority = p.rawValue
                                save()
                            }
                        }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        ParchmentFieldLabel(text: "Repeat")
                        ParchmentRecurrencePicker(rule: $task.recurrenceRule)
                            .onChange(of: task.recurrenceRule) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        ParchmentFieldLabel(text: "Notes (optional)")
                        TextEditor(text: $task.notes)
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: kLineSpacing * 3)
                            .padding(.horizontal, 52)
                            .onChange(of: task.notes) { _, _ in save() }

                        if task.isRolledOver, let original = task.originalDate {
                            Divider().padding(.horizontal, 56).opacity(0.15).padding(.top, 8)
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(inkColor.opacity(0.40))
                                Text("Rolled over from \(original.formatted(.dateTime.weekday(.wide).day().month()))")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.40))
                                    .italic()
                            }
                            .padding(.horizontal, 56)
                            .padding(.top, 14)
                        }

                        Divider().padding(.horizontal, 56).opacity(0.15).padding(.top, 8)

                        Button { confirmDelete = true } label: {
                            Text("Delete Task")
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(Color(red: 0.72, green: 0.10, blue: 0.10).opacity(0.80))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 56)
                        .padding(.top, 18)
                        .padding(.bottom, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.custom("Georgia", size: 15).bold())
                }
            }
            .confirmationDialog("Delete this task?",
                                isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(task)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}
