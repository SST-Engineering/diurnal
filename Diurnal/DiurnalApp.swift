import SwiftUI
import SwiftData

@main
struct DiurnalApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                DailyTask.self,
                Appointment.self,
                DailyNote.self,
                WeeklyCompass.self,
                Goal.self,
                MissionStatement.self,
            ])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to initialise ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

// MARK: - App Icon (Xcode 26 SwiftUI icon)

//struct DiurnalAppIcon: AppIcon {
//    var body: some View {
//       AppIconView(size: 1024)
//    }
//}
