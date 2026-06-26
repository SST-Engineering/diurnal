import SwiftUI
import SwiftData

struct AppointmentRowView: View {
    @Bindable var appointment: Appointment
    @State private var showDetail = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(appointment.startTime.formatted(.dateTime.hour().minute()))
                    .font(.caption.bold())
                Text(appointment.endTime.formatted(.dateTime.hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48)

            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                if !appointment.location.isEmpty {
                    Label(appointment.location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            AppointmentDetailView(appointment: appointment)
        }
    }
}

struct AppointmentDetailView: View {
    @Bindable var appointment: Appointment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var confirmDelete = false

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
                        Text("Edit Appointment")
                            .font(.custom("Georgia", size: 26))
                            .foregroundStyle(inkColor)
                            .padding(.top, 28)
                            .padding(.horizontal, 56)

                        Text(appointment.startTime.formatted(
                            .dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.custom("Georgia", size: 13))
                            .foregroundStyle(inkColor.opacity(0.45))
                            .italic()
                            .padding(.horizontal, 56)
                            .padding(.bottom, 10)

                        Divider().padding(.horizontal, 56).opacity(0.4)

                        // ── Title ────────────────────────────────────────
                        ParchmentFieldLabel(text: "Title")
                        TextField("", text: $appointment.title)
                            .font(.custom("Georgia", size: 16))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)
                            .onChange(of: appointment.title) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Location ─────────────────────────────────────
                        ParchmentFieldLabel(text: "Location (optional)")
                        TextField("", text: $appointment.location)
                            .font(.custom("Georgia", size: 15))
                            .foregroundStyle(inkColor)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 56)
                            .frame(height: kLineSpacing)
                            .onChange(of: appointment.location) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Time ──────────────────────────────────────────
                        ParchmentFieldLabel(text: "Time")

                        HStack(spacing: 0) {
                            Text("All Day")
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(inkColor.opacity(0.75))
                            Spacer()
                            Toggle("", isOn: $appointment.isAllDay)
                                .labelsHidden()
                                .tint(spineColor)
                                .onChange(of: appointment.isAllDay) { _, _ in save() }
                        }
                        .padding(.horizontal, 56)
                        .frame(height: kLineSpacing)

                        if !appointment.isAllDay {

                        HStack(spacing: 0) {
                            Text("Start")
                                .font(.custom("Georgia", size: 14))
                                .foregroundStyle(inkColor.opacity(0.55))
                                .frame(width: 52, alignment: .leading)
                            DatePicker("", selection: $appointment.startTime,
                                       displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .environment(\.colorScheme, .light)
                                .onChange(of: appointment.startTime) { _, newVal in
                                    if appointment.endTime <= newVal {
                                        appointment.endTime = Calendar.current.date(
                                            byAdding: .hour, value: 1, to: newVal) ?? newVal
                                    }
                                    save()
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
                            DatePicker("", selection: $appointment.endTime,
                                       in: appointment.startTime...,
                                       displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .environment(\.colorScheme, .light)
                                .onChange(of: appointment.endTime) { _, _ in save() }
                            Spacer()
                        }
                        .padding(.horizontal, 56)
                        .frame(height: kLineSpacing)

                        // Duration hint
                        let mins = Int(appointment.endTime.timeIntervalSince(appointment.startTime) / 60)
                        if mins > 0 {
                            Text("\(mins < 60 ? "\(mins) min" : "\(mins / 60)h\(mins % 60 > 0 ? " \(mins % 60)m" : "")")")
                                .font(.custom("Georgia", size: 12))
                                .foregroundStyle(inkColor.opacity(0.35))
                                .italic()
                                .padding(.horizontal, 56)
                                .padding(.bottom, 4)
                        }

                        } // end if !isAllDay

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Recurrence ────────────────────────────────────
                        ParchmentFieldLabel(text: "Repeat")
                        ParchmentRecurrencePicker(rule: $appointment.recurrenceRule)
                            .onChange(of: appointment.recurrenceRule) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.2).padding(.top, 4)

                        // ── Notes ─────────────────────────────────────────
                        ParchmentFieldLabel(text: "Notes (optional)")
                        TextEditor(text: $appointment.notes)
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: kLineSpacing * 3)
                            .padding(.horizontal, 52)
                            .onChange(of: appointment.notes) { _, _ in save() }

                        Divider().padding(.horizontal, 56).opacity(0.15).padding(.top, 8)

                        // ── Delete ────────────────────────────────────────
                        Button {
                            confirmDelete = true
                        } label: {
                            Text("Delete Appointment")
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
            .confirmationDialog("Delete this appointment?",
                                isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(appointment)
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }

    private func save() {
        try? modelContext.save()
    }
}
