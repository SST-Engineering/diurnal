import SwiftUI
import SwiftData

struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @Query private var allTasks: [DailyTask]
    @Query private var allAppointments: [Appointment]

    @AppStorage("calWeekFirstDay") private var calWeekFirstDay: Int = 2

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var weekdaySymbols: [String] {
        Calendar.current.veryShortWeekdaySymbols.rotated(by: calWeekFirstDay - 1)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthHeader
                weekdayHeader
                monthGrid
                Divider()
                DailyPageView(date: $selectedDate)
            }
        }
        .navigationTitle("Calendar")
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.title3.bold())
            Spacer()
            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    private var monthGrid: some View {
        let days = daysInMonth()
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let day {
                    DayCell(
                        date: day,
                        isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate),
                        isToday: Calendar.current.isDateInToday(day),
                        hasItems: dateHasItems(day)
                    )
                    .onTapGesture {
                        selectedDate = day
                    }
                } else {
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .padding()
    }

    private func daysInMonth() -> [Date?] {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: displayedMonth)!
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = (cal.component(.weekday, from: firstDay) - calWeekFirstDay + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(cal.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }

    private func dateHasItems(_ date: Date) -> Bool {
        allTasks.contains { Calendar.current.isDate($0.pageDate, inSameDayAs: date) } ||
        allAppointments.contains { Calendar.current.isDate($0.pageDate, inSameDayAs: date) }
    }

    private func shiftMonth(by value: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth)!
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasItems: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(date.formatted(.dateTime.day()))
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isSelected ? .white : isToday ? .accentColor : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : Color.clear)
                .clipShape(Circle())

            Circle()
                .fill(isSelected ? Color.white.opacity(0.7) : Color.accentColor)
                .frame(width: 5, height: 5)
                .opacity(hasItems ? 1 : 0)
        }
    }
}

private extension Array {
    func rotated(by offset: Int) -> [Element] {
        guard !isEmpty else { return self }
        let offset = offset % count
        return Array(self[offset...] + self[..<offset])
    }
}
