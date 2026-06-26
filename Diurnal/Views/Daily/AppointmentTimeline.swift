import SwiftUI

// MARK: - Appointment Timeline
// Visual time-scale from 08:00 to 18:00 in 30-minute slots.
// Each 30-min slot = kLineSpacing / 2 (14pt).
// Total grid height: 20 slots × 14pt = 280pt.
//
// Positioning strategy:
//   - GeometryReader fills the TimeGrid bounds.
//   - Each block uses .position(x:y:) which places the view's CENTRE
//     at an explicit coordinate — this is the only layout-safe way to
//     do absolute positioning in SwiftUI overlays.
//   - yOffset(for:) returns the TOP-EDGE y of the block; we add
//     blockH/2 to convert to the centre expected by .position().

struct AppointmentTimeline: View {
    let appointments: [Appointment]

    private let dayStartMin = 8 * 60        // 08:00 in minutes
    private let dayEndMin   = 18 * 60       // 18:00 in minutes
    private let slotCount   = 20            // 10 hours × 2 half-slots
    private let slotH: CGFloat = kLineSpacing / 2   // 14pt per 30 min
    private let labelW: CGFloat = 44
    private let apptBlue = Color(red: 0.25, green: 0.40, blue: 0.65)

    // ── Helpers ──────────────────────────────────────────────────────────

    /// Minutes elapsed since midnight (local calendar) for date d.
    private func msm(_ d: Date) -> Int {
        let startOfDay = Calendar.current.startOfDay(for: d)
        return Int(d.timeIntervalSince(startOfDay) / 60.0)
    }

    /// Top-edge y offset (pt) within the 08:00–18:00 grid for a given time.
    private func yOffset(for date: Date) -> CGFloat {
        let minutesPastMidnight = Double(msm(date))
        return CGFloat(minutesPastMidnight - Double(dayStartMin)) * slotH / 30.0
    }

    private func blockH(for appt: Appointment) -> CGFloat {
        let mins = Int(appt.duration / 60)
        return max(slotH, CGFloat(mins) * slotH / 30.0)
    }

    // ── Filtered groups ──────────────────────────────────────────────────

    private var allDayAppts: [Appointment] {
        appointments.filter { $0.isAllDay }.sorted { $0.title < $1.title }
    }

    private var timedAppts: [Appointment] {
        appointments.filter { !$0.isAllDay }
    }

    private var earlyAppts: [Appointment] {
        timedAppts.filter { msm($0.startTime) < dayStartMin }
    }

    private var mainAppts: [Appointment] {
        timedAppts
            .filter { msm($0.startTime) >= dayStartMin && msm($0.startTime) < dayEndMin }
            .sorted { $0.startTime < $1.startTime }
    }

    private var lateAppts: [Appointment] {
        timedAppts.filter { msm($0.startTime) >= dayEndMin }
    }

    // ── Body ─────────────────────────────────────────────────────────────

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !allDayAppts.isEmpty {
                AllDaySection(appts: allDayAppts, labelW: labelW, apptBlue: apptBlue)
            }

            if !earlyAppts.isEmpty {
                OffScheduleSection(title: "Before 08:00", appts: earlyAppts,
                                   labelW: labelW, apptBlue: apptBlue)
            }

            // GeometryReader gives us the grid's exact coordinate space so
            // we can use .position(x:y:) for pixel-perfect placement.
            TimeGrid(slotCount: slotCount, slotH: slotH,
                     labelW: labelW, dayStartMin: dayStartMin)
                .overlay {
                    GeometryReader { geo in
                        let gridW = geo.size.width
                        ForEach(mainAppts) { appt in
                            let top = yOffset(for: appt.startTime)
                            let bh  = blockH(for: appt)
                            AppointmentBlock(
                                appt: appt,
                                labelW: labelW,
                                apptBlue: apptBlue,
                                height: bh
                            )
                            .frame(width: gridW, height: bh)
                            // .position places the VIEW CENTRE at (x, y)
                            .position(x: gridW / 2, y: top + bh / 2)
                        }
                    }
                }
                .clipped()

            if !lateAppts.isEmpty {
                OffScheduleSection(title: "After 18:00", appts: lateAppts,
                                   labelW: labelW, apptBlue: apptBlue)
            }
        }
    }
}

// MARK: - Time grid

private struct TimeGrid: View {
    let slotCount: Int
    let slotH: CGFloat
    let labelW: CGFloat
    let dayStartMin: Int

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(0..<slotCount), id: \.self) { slot in
                TimeSlotRow(slot: slot, slotH: slotH,
                            labelW: labelW, dayStartMin: dayStartMin)
            }
        }
    }
}

private struct TimeSlotRow: View {
    let slot: Int
    let slotH: CGFloat
    let labelW: CGFloat
    let dayStartMin: Int

    private var isHour: Bool { slot % 2 == 0 }
    private var displayHour: Int { dayStartMin / 60 + slot / 2 }

    var body: some View {
        // Separator is at the TOP of each slot so that the "HH:00" label
        // and the separator line both sit at y = slot * slotH — exactly
        // where yOffset() places the corresponding appointment block.
        HStack(alignment: .top, spacing: 6) {
            Group {
                if isHour {
                    Text(String(format: "%02d:00", displayHour))
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(inkColor.opacity(0.70))
                        .monospacedDigit()
                        .offset(y: -6)   // lift label so its baseline sits on the rule
                } else {
                    Color.clear
                }
            }
            .frame(width: labelW, alignment: .trailing)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(isHour ? ruleColor.opacity(0.85) : ruleColor.opacity(0.28))
                    .frame(height: isHour ? 0.7 : 0.35)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: slotH)
    }
}

// MARK: - Appointment block (tappable → edit sheet)

private struct AppointmentBlock: View {
    var appt: Appointment
    let labelW: CGFloat
    let apptBlue: Color
    let height: CGFloat
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: labelW, height: height)

            Button { showEdit = true } label: {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(apptBlue.opacity(0.12))
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(apptBlue.opacity(0.45), lineWidth: 0.75)

                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(apptBlue)
                            .frame(width: 3)
                            .clipShape(RoundedRectangle(cornerRadius: 1.5))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(appt.title)
                                .font(.custom("Georgia", size: 11))
                                .foregroundStyle(inkColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(
                                "\(appt.startTime.formatted(.dateTime.hour().minute())) – " +
                                "\(appt.endTime.formatted(.dateTime.hour().minute()))"
                            )
                            .font(.custom("Georgia", size: 9))
                            .foregroundStyle(inkColor.opacity(0.55))
                            .monospacedDigit()
                        }
                        Spacer()
                    }
                }
                .frame(height: height)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showEdit) {
                AppointmentDetailView(appointment: appt)
            }
        }
    }
}

// MARK: - All-day section

private struct AllDaySection: View {
    let appts: [Appointment]
    let labelW: CGFloat
    let apptBlue: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("All Day")
                    .font(.custom("Georgia", size: 9))
                    .foregroundStyle(inkColor.opacity(0.55))
                    .textCase(.uppercase)
                    .kerning(1.0)
                    .frame(width: labelW, alignment: .trailing)
                Rectangle()
                    .fill(ruleColor.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: 0.5)
            }
            .padding(.bottom, 2)

            ForEach(appts) { appt in
                AllDayBlock(appt: appt, labelW: labelW, apptBlue: apptBlue)
            }
        }
        .padding(.bottom, 4)
    }
}

private struct AllDayBlock: View {
    var appt: Appointment
    let labelW: CGFloat
    let apptBlue: Color
    @State private var showEdit = false

    var body: some View {
        HStack(spacing: 6) {
            Color.clear.frame(width: labelW, height: kLineSpacing)

            Button { showEdit = true } label: {
                HStack(spacing: 5) {
                    Rectangle()
                        .fill(apptBlue)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 1.5))

                    Text(appt.title)
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(inkColor)
                        .lineLimit(1)

                    if !appt.recurrenceRule.isEmpty {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 8))
                            .foregroundStyle(inkColor.opacity(0.45))
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: kLineSpacing * 0.85)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(apptBlue.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(apptBlue.opacity(0.35), lineWidth: 0.6)
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showEdit) {
                AppointmentDetailView(appointment: appt)
            }
        }
    }
}

// MARK: - Before / after section

private struct OffScheduleSection: View {
    let title: String
    let appts: [Appointment]
    let labelW: CGFloat
    let apptBlue: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.custom("Georgia", size: 9))
                .foregroundStyle(inkColor.opacity(0.55))
                .textCase(.uppercase)
                .kerning(1.0)
                .padding(.top, 4)
                .padding(.bottom, 2)

            ForEach(appts) { appt in
                HStack(spacing: 6) {
                    Text(appt.startTime.formatted(.dateTime.hour().minute()))
                        .font(.custom("Georgia", size: 11))
                        .foregroundStyle(inkColor.opacity(0.70))
                        .frame(width: labelW, alignment: .trailing)
                        .monospacedDigit()

                    Rectangle()
                        .fill(apptBlue)
                        .frame(width: 2, height: 10)
                        .clipShape(Capsule())

                    Text(appt.title)
                        .font(.custom("Georgia", size: 12))
                        .foregroundStyle(inkColor)

                    Spacer()
                }
                .frame(height: kLineSpacing * 0.75)
            }
        }
    }
}
