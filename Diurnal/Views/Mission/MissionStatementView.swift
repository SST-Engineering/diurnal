import SwiftUI
import SwiftData

struct MissionStatementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var statements: [MissionStatement]
    @State private var isEditing = false

    private var statement: MissionStatement {
        if let existing = statements.first { return existing }
        let new = MissionStatement()
        modelContext.insert(new)
        return new
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
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Compass")
                            .font(.custom("Georgia", size: 26))
                            .foregroundStyle(inkColor)
                        Text("Your personal direction — what you stand for and where you are headed.")
                            .font(.custom("Georgia", size: 13))
                            .foregroundStyle(inkColor.opacity(0.45))
                            .italic()
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 56)

                    Divider().padding(.horizontal, 56).opacity(0.4)

                    // Content area
                    if isEditing || statement.content.isEmpty {
                        TextEditor(text: Bindable(statement).content)
                            .font(.custom("Georgia", size: 15))
                            .foregroundStyle(inkColor)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .lineSpacing(kLineSpacing - 17)
                            .frame(minHeight: 240)
                            .padding(.horizontal, 52)
                            .onChange(of: statement.content) { _, _ in
                                statement.updatedAt = Date()
                                try? modelContext.save()
                            }
                    } else {
                        Text(statement.content)
                            .font(.custom("Georgia", size: 15))
                            .foregroundStyle(inkColor)
                            .lineSpacing(kLineSpacing - 17)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 52)
                            .onTapGesture { isEditing = true }
                    }

                    if !statement.content.isEmpty {
                        Text("Last updated \(statement.updatedAt.formatted(.relative(presentation: .named)))")
                            .font(.custom("Georgia", size: 11))
                            .foregroundStyle(inkColor.opacity(0.30))
                            .italic()
                            .padding(.horizontal, 56)
                    }

                    // Writing prompts when empty
                    if statement.content.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Prompts to find your compass:")
                                .font(.custom("Georgia", size: 12))
                                .foregroundStyle(inkColor.opacity(0.45))
                                .textCase(.uppercase)
                                .kerning(1.2)
                            ForEach(prompts, id: \.self) { prompt in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("–")
                                        .foregroundStyle(inkColor.opacity(0.30))
                                    Text(prompt)
                                        .foregroundStyle(inkColor.opacity(0.45))
                                        .italic()
                                }
                                .font(.custom("Georgia", size: 13))
                            }
                        }
                        .padding(.horizontal, 56)
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Compass")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("Done") { isEditing = false }
                        .bold()
                } else {
                    Button("Edit") { isEditing = true }
                }
            }
        }
    }

    private let prompts = [
        "What do you want to be remembered for?",
        "What principles guide your decisions?",
        "What do you want to contribute to the world?",
        "Who matters most to you, and how do you want to show up for them?",
        "What would your ideal self look like in 10 years?",
    ]
}
