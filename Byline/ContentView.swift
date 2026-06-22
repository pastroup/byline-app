import SwiftUI
import AppKit
import Combine

struct ContentView: View {
    @EnvironmentObject var store: DocumentStore
    @EnvironmentObject var focus: EditorFocusController

    @AppStorage("byline:leftFraction") private var leftFraction: Double = 0.45
    @State private var debouncedHTML: String = ""

    var body: some View {
        SplitContainer(
            fraction: $leftFraction,
            left: { EditorPane() },
            right: { previewPane }
        )
        .frame(minWidth: 1040, minHeight: 700)
        .toolbar { toolbarContent }
        .onAppear {
            debouncedHTML = NewsletterRenderer.html(for: store.doc,
                                                    mobile: store.doc.previewMode == .mobile)
        }
        .onReceive(
            store.$doc
                .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        ) { doc in
            debouncedHTML = NewsletterRenderer.html(for: doc, mobile: doc.previewMode == .mobile)
        }
        .confirmationDialog("Reset to defaults?", isPresented: $store.showResetConfirm) {
            Button("Reset", role: .destructive) { store.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces your current draft with the default content. This can\u{2019}t be undone.")
        }
        .confirmationDialog("Clear all fields?", isPresented: $store.showClearConfirm) {
            Button("Clear All", role: .destructive) { store.clearAllFields() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This blanks the content fields and sets the date to today. The eyebrow, byline, section headers, and footer keep their defaults, and your theme is unchanged. This can\u{2019}t be undone.")
        }
        .confirmationDialog("Set current view as default?", isPresented: $store.showSetDefaultConfirm) {
            Button("Set as Default") { store.setCurrentAsDefault() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("New issues, Reset to Defaults, and Clear All Fields will start from the current content and formatting. This overwrites the previous default.")
        }
    }

    // MARK: Preview pane

    private var previewPane: some View {
        // The WKWebView scrolls natively, so it must not be nested in a
        // SwiftUI ScrollView (that produces a second pair of scrollbars).
        ZStack {
            Color(hex: store.doc.theme.pageBg)
            // The HTML centers its own column (600px desktop / 380px mobile) on
            // the page background, so the web view simply fills the pane.
            WebPreview(html: debouncedHTML)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Picker("", selection: $store.doc.previewMode) {
                Text("Desktop").tag(NewsletterDocument.PreviewMode.desktop)
                Text("Mobile").tag(NewsletterDocument.PreviewMode.mobile)
            }
            .pickerStyle(.segmented)
            .fixedSize()

            Button("Copy HTML") { copyHTML() }
                .buttonStyle(.bordered)
            Button("Export HTML\u{2026}") { exportHTML() }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: store.doc.theme.accent))
        }
    }

    // MARK: Actions

    private func copyHTML() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(store.html, forType: .string)
        store.statusMessage = "Copied HTML"
    }

    private func exportHTML() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = store.exportFilename
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try store.html.write(to: url, atomically: true, encoding: .utf8)
                store.statusMessage = "Exported"
            } catch {
                store.statusMessage = "Export failed"
            }
        }
    }
}

// MARK: - Resizable split with a draggable divider (position persisted)

struct SplitContainer<Left: View, Right: View>: View {
    @Binding var fraction: Double
    @ViewBuilder var left: () -> Left
    @ViewBuilder var right: () -> Right

    private let minF = 0.22
    private let maxF = 0.78
    @State private var startFraction: Double?

    var body: some View {
        GeometryReader { geo in
            let total = geo.size.width
            let leftWidth = total * min(maxF, max(minF, fraction))

            HStack(spacing: 0) {
                left()
                    .frame(width: leftWidth)
                    .clipped()

                Rectangle()
                    .fill(Color(white: 0.86))
                    .frame(width: 8)
                    .overlay(
                        Rectangle()
                            .fill(Color(white: 0.6))
                            .frame(width: 1, height: 24)
                    )
                    .contentShape(Rectangle())
                    .onHover { inside in
                        if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard total > 0 else { return }
                                // Use translation (coordinate-space independent)
                                // from the fraction captured at drag start.
                                let base = startFraction ?? fraction
                                if startFraction == nil { startFraction = fraction }
                                fraction = min(maxF, max(minF, base + value.translation.width / total))
                            }
                            .onEnded { _ in startFraction = nil }
                    )

                right()
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
    }
}
