import SwiftUI

// MARK: - Cross-platform background colours

extension Color {
    static var secondaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    static var tertiaryBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.tertiarySystemBackground)
        #endif
    }
}

// MARK: - Cross-platform .navigationBarTitleDisplayMode

extension View {
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
