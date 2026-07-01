import SwiftUI
import SwiftData

struct WeeklyCompassView: View {
    let date: Date
    @Environment(\.modelContext) private var modelContext
    @Query private var allCompass: [WeeklyCompass]

    @State private var weekOffset = 0

    private var effectiveDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weekOffset, to: date) ?? date
    }
    private var weekStart: Date { WeeklyCompass.monday(for: effectiveDate) }

    private var compass: WeeklyCompass {
        if let existing = allCompass.first(where: {
            Calendar.current.isDate($0.weekStart, inSameDayAs: weekStart)
        }) { return existing }
        let new = WeeklyCompass(weekStart: weekStart)
        modelContext.insert(new)
        return new
    }

    var body: some View {
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
                VStack(alignment: .leading, spacing: 24) {
                    weekHeader
                        .padding(.top, 28)
                        .padding(.horizontal, 56)

                    Divider()
                        .padding(.horizontal, 56)
                        .opacity(0.4)

                    parchmentSection(title: "Goals for this week", icon: "flag.fill") {
                        TextEditor(text: Bindable(compass).weeklyGoals)
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 88)
                            .onChange(of: compass.weeklyGoals) { _, _ in
                                compass.updatedAt = Date()
                                try? modelContext.save()
                            }
                    }

                    Divider().padding(.horizontal, 56).opacity(0.3)

                    // Learning and Renewal
                    VStack(alignment: .leading, spacing: 4) {
                        BookSectionHeader(title: "Learning and Renewal", icon: "leaf.fill")
                        Text("Personal renewal across four dimensions")
                            .font(.custom("Georgia", size: 12))
                            .foregroundStyle(inkColor.opacity(0.40))
                            .italic()
                    }
                    .padding(.horizontal, 56)

                    renewalField(
                        title: "Training / Sport", icon: "figure.run",
                        color: Color(red: 0.20, green: 0.55, blue: 0.25),
                        text: Bindable(compass).physicalRenewal
                    )
                    renewalField(
                        title: "Social", icon: "heart.fill",
                        color: Color(red: 0.75, green: 0.20, blue: 0.35),
                        text: Bindable(compass).socialRenewal
                    )
                    renewalField(
                        title: "Emotional", icon: "brain",
                        color: Color(red: 0.35, green: 0.25, blue: 0.65),
                        text: Bindable(compass).mentalRenewal
                    )
                    renewalField(
                        title: "Growth", icon: "sparkles",
                        color: Color(red: 0.65, green: 0.50, blue: 0.10),
                        text: Bindable(compass).spiritualRenewal
                    )

                    Divider().padding(.horizontal, 56).opacity(0.3)

                    parchmentSection(title: "Notes", icon: "note.text") {
                        TextEditor(text: Bindable(compass).notes)
                            .font(.custom("Georgia", size: 14))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 72)
                            .onChange(of: compass.notes) { _, _ in
                                compass.updatedAt = Date()
                                try? modelContext.save()
                            }
                    }

                    Spacer(minLength: 40)
                }
            }
            // Back chevron — top-left
            VStack {
                Button { weekOffset -= 1 } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .thin))
                        .foregroundStyle(inkColor.opacity(0.75))
                        .padding(16)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Forward chevron — top-right
            VStack {
                Button { weekOffset += 1 } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 30, weight: .thin))
                        .foregroundStyle(inkColor.opacity(0.75))
                        .padding(16)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .navigationTitle("Week's Aims")
    }

    // MARK: - Week header

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Week of")
                .font(.custom("Georgia", size: 12))
                .foregroundStyle(inkColor.opacity(0.50))
                .textCase(.uppercase)
                .kerning(1.4)
            Text("\(compass.weekStart.formatted(.dateTime.day().month(.wide))) – \(compass.weekEnd.formatted(.dateTime.day().month(.wide).year()))")
                .font(.custom("Georgia", size: 22))
                .foregroundStyle(inkColor)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func parchmentSection<Content: View>(
        title: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BookSectionHeader(title: title, icon: icon)
            content()
        }
        .padding(.horizontal, 56)
    }

    @ViewBuilder
    private func renewalField(
        title: String, icon: String, color: Color,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.custom("Georgia", size: 12).bold())
                .foregroundStyle(color)
                .textCase(.uppercase)
                .kerning(1.0)
            TextEditor(text: text)
                .font(.custom("Georgia", size: 14))
                .foregroundStyle(inkColor)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: kLineSpacing * 2)
                .onChange(of: text.wrappedValue) { _, _ in
                    compass.updatedAt = Date()
                    try? modelContext.save()
                }
        }
        .padding(.horizontal, 56)
    }
}
