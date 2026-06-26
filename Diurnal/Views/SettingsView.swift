import SwiftUI

// MARK: - App-wide settings
// Stored in UserDefaults via @AppStorage so they persist across launches.
// calWeekFirstDay: 1 = Sunday, 2 = Monday (Calendar weekday convention)

struct SettingsView: View {
    @AppStorage("calWeekFirstDay") var calWeekFirstDay: Int = 2
    @Environment(\.dismiss) private var dismiss

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

                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.custom("Georgia", size: 26))
                        .foregroundStyle(inkColor)
                        .padding(.top, 28)
                        .padding(.horizontal, 56)

                    Divider().padding(.horizontal, 56).opacity(0.4).padding(.top, 10)

                    ParchmentFieldLabel(text: "Week starts on")

                    HStack(spacing: 6) {
                        ForEach([(2, "Monday"), (1, "Sunday")], id: \.0) { value, label in
                            Button { calWeekFirstDay = value } label: {
                                Text(label)
                                    .font(.custom("Georgia", size: 14))
                                    .foregroundStyle(calWeekFirstDay == value ? pageColor : inkColor.opacity(0.70))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(calWeekFirstDay == value ? inkColor.opacity(0.75) : inkColor.opacity(0.07))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 56)
                    .frame(height: kLineSpacing)

                    Spacer()
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
        }
    }
}
