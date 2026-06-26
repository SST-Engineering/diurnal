import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedSidebarItem: SidebarItem? = .today
    @State private var showSearch = false
    @State private var showSettings = false
//    @State private var showIconExporter = false

    var body: some View {
        Group {
            if sizeClass == .compact {
                iPhoneLayout
            } else {
                wideLayout
            }
        }
        .sheet(isPresented: $showSearch) {
            SearchView(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 420, minHeight: 320)
        }
//        .sheet(isPresented: $showIconExporter) {
//            IconExporterView()
//                .frame(minWidth: 520, minHeight: 600)
//        }
    }

    // MARK: - iPhone

    private var iPhoneLayout: some View {
        TabView {
            DailyPageView(date: $selectedDate)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showSearch = true } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }

            CalendarView(selectedDate: $selectedDate)
                .tabItem { Label("Calendar", systemImage: "calendar") }

            WeeklyCompassView(date: selectedDate)
                .tabItem { Label("Week's Aims", systemImage: "arrow.trianglehead.2.clockwise.rotate.90") }
        }
    }

    // MARK: - iPad / Mac

    private var wideLayout: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                Label(item.title, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Diurnal")
            .listStyle(.sidebar)
        } detail: {
            switch selectedSidebarItem {
            case .today, nil:
                DailyPageView(date: $selectedDate)
            case .calendar:
                CalendarView(selectedDate: $selectedDate)
            case .weeklyCompass:
                WeeklyCompassView(date: selectedDate)
            }
        }
        // Search and settings sit in the window toolbar
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showSearch = true } label: {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showSettings = true } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
//            // ── TEMPORARY: remove after exporting the icon ──
//            ToolbarItem(placement: .automatic) {
//                Button { showIconExporter = true } label: {
//                    Label("Export Icon", systemImage: "square.and.arrow.down")
//                }
//            }
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case today         = "Today"
    case calendar      = "Calendar"
    case weeklyCompass = "Week's Aims"

    var id: String { rawValue }
    var title: String { rawValue }

    var icon: String {
        switch self {
        case .today:         return "sun.max.fill"
        case .calendar:      return "calendar"
        case .weeklyCompass: return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
}
