import SwiftUI
import AppKit

@main
struct BylineApp: App {
    @StateObject private var store = DocumentStore()
    @StateObject private var focus = EditorFocusController()

    var body: some Scene {
        WindowGroup("Byline") {
            ContentView()
                .environmentObject(store)
                .environmentObject(focus)
        }
        .defaultSize(width: 1280, height: 860)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Byline") { Self.showAboutPanel() }
            }
            CommandGroup(replacing: .newItem) {} // single window
            CommandGroup(after: .newItem) {
                Button("Open Draft\u{2026}") { store.openDraft() }
                    .keyboardShortcut("o", modifiers: .command)
                Button("Save Draft\u{2026}") { store.saveDraft() }
                    .keyboardShortcut("s", modifiers: .command)
                Divider()
                Button("Reset to Defaults\u{2026}") { store.showResetConfirm = true }
                Button("Clear All Fields\u{2026}") { store.showClearConfirm = true }
                Button("Set Current View as Default\u{2026}") { store.showSetDefaultConfirm = true }
            }
        }
    }

    /// Custom About panel with the developer note and beta disclaimer.
    static func showAboutPanel() {
        let note = """
        Developed by Paul Stroup.

        Beta product that likely contains errors. Verify all links, text, and formatting before using in final client communication.

        Contact Paul for edits, changes, or bugs in the program.
        """
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 2
        let credits = NSAttributedString(string: note, attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: style,
        ])
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
        NSApp.activate(ignoringOtherApps: true)
    }
}
