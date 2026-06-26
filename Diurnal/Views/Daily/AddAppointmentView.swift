import SwiftUI
import SwiftData

struct AddAppointmentView: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var location = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes = ""
    @State private var isAllDay = false
    @State private var recurrenceRule = ""

    init(date: Date) {
        self.date = date
        let cal = Calendar.current
        let now = Date()
        let hour = cal.component(.hour, from: now)
        _startTime = State(initialValue: cal.date(bySettingHour: max(8, hour + 1), minute: 0, second: 0, of: date) ?? date)
        _endTime   = State(initialValue: cal.date(bySettingHour: max(9, hour + 2), minute: 0, second: 0, of: date) ?? date)
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
                        Text("New Appointment")
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

                        // ── Title ───────────────────────────────────────
                        ParchmentFieldLabel(text: "Title")
                        TextField("", text: $title)
                            .font(.custom("Georgia", size: 16))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Location ────────────────────────────────────
                        ParchmentFieldLabel(text: "Location (optional)")
                        TextField("", text: $location)
                            .font(.custom("Georgia", size: 15))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Time ────────────────────────────────────────
                        ParchmentFieldLabel(text: "Time")

                        HStack(spacing: 0) {
                            Text("All Day")
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(inkColor.opacity(0.75))
                            Spacer()
                            Toggle("", isOn: $isAllDay)
                                .labelsHidden()
                                .tint(spineColor)
                        }
                        .padding(.horizontal, 56)
                        .frame(height: kLineSpacing)

                        if !isAllDay {
                            HStack(spacing: 0) {
                                Text("Start")
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.55))
                                    .frame(width: 52, alignment: .leading)
                                DatePicker("", selection: $startTime, displayedComponents: [.hourAndMinute])
                                    .labelsHidden()
                                    .environment(\.colorScheme, .light)
                                    .onChange(of: startTime) { _, newVal in
                                        if endTime <= newVal {
                                            endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newVal) ?? newVal
                                        }
                                    }
                                Spacer()
                            }
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)

                            HStack(spacing: 0) {
                                Text("End")
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundStyle(inkColor.opacity(0.55))
                                    .frame(width: 52, alignment: .leading)
                                DatePicker("", selection: $endTime,
                                           in: startTime...,
                                           displayedComponents: [.hourAndMinute])
                                    .labelsHidden()
                                    .environment(\.colorScheme, .light)
                                Spacer()
                            }
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)

                            let mins = Int(endTime.timeIntervalSince(startTime) / 60)
                            if mins > 0 {
                                Text("\(mins < 60 ? "\(mins) min" : "\(mins / 60)h\(mins % 60 > 0 ? " \(mins % 60)m" : "")")")
                                    .font(.custom("Georgia", size: 12))
                                    .foregroundStyle(inkColor.opacity(0.35))
                                    .italic()
                                    .padding(.horizontal, 56)
                                    .padding(.bottom, 4)
                            }
                        }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Recurrence ──────────────────────────────────
                        ParchmentFieldLabel(text: "Repeat")
                        ParchmentRecurrencePicker(rule: $recurrenceRule)

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
        let appt = Appointment(
            pageDate: date,
            startTime: startTime,
            endTime: endTime,
            title: title.trimmingCharacters(in: .whitespaces)
        )
        appt.location = location
        appt.notes = notes
        appt.isAllDay = isAllDay
        appt.recurrenceRule = recurrenceRule
        modelContext.insert(appt)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Recurrence chip picker (shared with edit view)

struct ParchmentRecurrencePicker: View {
    @Binding var rule: String

    private let options: [(String, String)] = [
        ("",        "None"),
        ("daily",   "Daily"),
        ("weekly",  "Weekly"),
        ("monthly", "Monthly"),
        ("yearly",  "Yearly"),
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.0) { value, label in
                Button { rule = value } label: {
                    Text(label)
                        .font(.custom("Georgia", size: 12))
                        .foregroundStyle(rule == value ? pageColor : inkColor.opacity(0.70))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(rule == value ? inkColor.opacity(0.72) : inkColor.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 56)
        .frame(height: kLineSpacing)
    }
}
