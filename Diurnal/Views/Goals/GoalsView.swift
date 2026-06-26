import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt) private var goals: [Goal]
    @State private var showAddGoal = false
    @State private var showCompleted = false

    private func goals(for timeframe: GoalTimeframe) -> [Goal] {
        goals.filter { $0.timeframe == timeframe.rawValue && $0.isComplete == showCompleted }
    }

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
                    // Page title
                    Text("Aims")
                        .font(.custom("Georgia", size: 26))
                        .foregroundStyle(inkColor)
                        .padding(.top, 28)
                        .padding(.horizontal, 56)
                        .padding(.bottom, 12)

                    Divider().padding(.horizontal, 56).opacity(0.4)

                    ForEach(GoalTimeframe.allCases, id: \.self) { timeframe in
                        let items = goals(for: timeframe)
                        if !items.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Label(timeframe.rawValue, systemImage: timeframe.icon)
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.50))
                                    .textCase(.uppercase)
                                    .kerning(1.2)
                                    .padding(.horizontal, 56)
                                    .padding(.top, 20)
                                    .padding(.bottom, 6)

                                ForEach(items) { goal in
                                    ParchmentGoalRow(goal: goal)
                                        .padding(.horizontal, 56)
                                }
                            }
                        }
                    }

                    if goals.filter({ !$0.isComplete }).isEmpty && !showCompleted {
                        VStack(spacing: 8) {
                            Image(systemName: "target")
                                .font(.system(size: 36))
                                .foregroundStyle(inkColor.opacity(0.20))
                            Text("No aims yet")
                                .font(.custom("Georgia", size: 16))
                                .foregroundStyle(inkColor.opacity(0.35))
                                .italic()
                            Text("Tap + to add your first aim")
                                .font(.custom("Georgia", size: 13))
                                .foregroundStyle(inkColor.opacity(0.25))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Aims")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddGoal = true } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Toggle(showCompleted ? "Showing Completed" : "Show Completed", isOn: $showCompleted)
            }
        }
        .sheet(isPresented: $showAddGoal) { AddGoalView() }
    }
}

// MARK: - Parchment-styled goal row

struct ParchmentGoalRow: View {
    @Bindable var goal: Goal
    @Environment(\.modelContext) private var modelContext
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    goal.isComplete.toggle()
                    if goal.isComplete { goal.completedAt = Date() }
                    try? modelContext.save()
                }
            } label: {
                Image(systemName: goal.isComplete ? "checkmark.square" : "square")
                    .foregroundStyle(inkColor.opacity(0.65))
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.custom("Georgia", size: 14))
                    .foregroundStyle(goal.isComplete ? inkColor.opacity(0.40) : inkColor)
                    .strikethrough(goal.isComplete, color: inkColor.opacity(0.40))
                if let target = goal.targetDate {
                    Text(target.formatted(.dateTime.day().month(.abbreviated).year()))
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(inkColor.opacity(0.40))
                        .italic()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture { showDetail = true }
        }
        .frame(minHeight: kLineSpacing)
        .sheet(isPresented: $showDetail) { GoalDetailView(goal: goal) }
    }
}

// MARK: - Add & Detail views (unchanged logic, updated titles)

struct GoalDetailView: View {
    @Bindable var goal: Goal
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var hasTargetDate = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Aim", text: $goal.title)
                    Picker("Timeframe", selection: $goal.timeframe) {
                        ForEach(GoalTimeframe.allCases, id: \.self) { t in
                            Text(t.rawValue).tag(t.rawValue)
                        }
                    }
                }
                Section("Target Date") {
                    Toggle("Set target date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target", selection: Binding(
                            get: { goal.targetDate ?? Date() },
                            set: { goal.targetDate = $0 }
                        ), displayedComponents: [.date])
                    }
                }
                Section("Progress Notes") {
                    TextEditor(text: $goal.progressNotes)
                        .frame(minHeight: 80)
                }
                Section {
                    Button("Delete Aim", role: .destructive) {
                        modelContext.delete(goal)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Aim")
            .inlineNavigationTitle()
            .onAppear { hasTargetDate = goal.targetDate != nil }
            .onChange(of: hasTargetDate) { _, val in if !val { goal.targetDate = nil } }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var timeframe: GoalTimeframe = .shortRange
    @State private var hasTargetDate = false
    @State private var targetDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Aim", text: $title)
                }
                Section {
                    Picker("Timeframe", selection: $timeframe) {
                        ForEach(GoalTimeframe.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                }
                Section {
                    Toggle("Set target date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target", selection: $targetDate, displayedComponents: [.date])
                    }
                }
            }
            .navigationTitle("New Aim")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let goal = Goal(title: title.trimmingCharacters(in: .whitespaces), timeframe: timeframe)
        if hasTargetDate { goal.targetDate = targetDate }
        modelContext.insert(goal)
        try? modelContext.save()
        dismiss()
    }
}
