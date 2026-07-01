#if os(macOS)
import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct IconExporterView: View {
    @State private var status: String = ""
    @State private var exported = false
    @State private var exportedURL: URL?

    var body: some View {
        VStack(spacing: 28) {
            AppIconView(size: 320)
                .clipShape(RoundedRectangle(cornerRadius: 320 * 0.225))
                .shadow(color: .black.opacity(0.35), radius: 24, y: 8)

            VStack(spacing: 12) {
                Button {
                    exportIcon()
                } label: {
                    Label(
                        exported ? "Icon Exported ✓" : "Export Icon PNG",
                        systemImage: exported ? "checkmark.circle.fill" : "square.and.arrow.up"
                    )
                    .font(.headline)
                    .frame(minWidth: 260)
                }
                .buttonStyle(.borderedProminent)
                .tint(exported ? .green : .accentColor)
                .controlSize(.large)

                if let url = exportedURL {
                    Button {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }

                if !status.isEmpty {
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(exported ? .green : .red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                }
            }

            if exported {
                GroupBox {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next steps:")
                            .font(.callout.bold())
                        Text("1. Click \"Show in Finder\" above")
                        Text("2. In Xcode Project Navigator, right-click → Add Files to \"Diurnal\" → select Assets.xcassets → also drag DiurnalIcon-1024.png into the AppIcon.appiconset folder")
                        Text("3. In Xcode: Diurnal target → General → App Icon = AppIcon")
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 420)
            }
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Render & save to temp (no sandbox entitlement needed)

    @MainActor
    private func exportIcon() {
        let size: CGFloat = 1024
        let renderer = ImageRenderer(
            content: AppIconView(size: size).frame(width: size, height: size)
        )
        renderer.scale = 1.0

        guard let cgImage = renderer.cgImage else {
            status = "Render failed — could not produce image"
            return
        }

        let rep = NSBitmapImageRep(cgImage: cgImage)
        rep.size = NSSize(width: size, height: size)

        guard let png = rep.representation(using: .png, properties: [:]) else {
            status = "PNG conversion failed"
            return
        }

        // Write to the AppIcon.appiconset folder directly
        let iconsetURL = URL(fileURLWithPath:
            "/Users/simonrolph/Development/Diurnal/Diurnal/Assets.xcassets/AppIcon.appiconset/DiurnalIcon-1024.png"
        )

        do {
            try png.write(to: iconsetURL)
            exportedURL = iconsetURL
            status = "Saved directly into AppIcon.appiconset ✓\nXcode will pick it up automatically."
            exported = true
        } catch {
            // Fallback: write to temp folder
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("DiurnalIcon-1024.png")
            do {
                try png.write(to: tmp)
                exportedURL = tmp
                status = "Saved to temp folder — click Show in Finder to locate it"
                exported = true
            } catch {
                status = "Save failed: \(error.localizedDescription)"
            }
        }
    }
}
#endif
