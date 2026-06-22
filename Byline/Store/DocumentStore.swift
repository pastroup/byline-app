import Foundation
import Combine
import AppKit
import UniformTypeIdentifiers

/// Holds the live document and exposes the actions wired to the window toolbar.
/// Save / Open use a single-slot JSON draft in UserDefaults (`byline:doc`),
/// mirroring the design's localStorage behavior.
final class DocumentStore: ObservableObject {

    @Published var doc: NewsletterDocument
    @Published var statusMessage: String = "Draft"
    @Published var showResetConfirm: Bool = false
    @Published var showClearConfirm: Bool = false
    @Published var showSetDefaultConfirm: Bool = false

    /// Marks the hidden HTML comment that carries the full editable document
    /// inside a saved draft, so Open can restore every field exactly.
    private static let draftMarkerPrefix = "byline-doc:v1:"

    /// UserDefaults slot holding the user's saved "default" document, set via
    /// "Set Current View as Default". Falls back to the built-in sample.
    private static let defaultDocKey = "byline:defaultDoc"

    init() {
        self.doc = Self.loadDefaults()
    }

    /// The document the app starts from and that Reset / Clear build on: the
    /// user's saved default if present, otherwise the built-in sample.
    static func loadDefaults() -> NewsletterDocument {
        if let data = UserDefaults.standard.data(forKey: defaultDocKey),
           let saved = try? JSONDecoder().decode(NewsletterDocument.self, from: data) {
            return saved
        }
        return NewsletterDocument.defaults()
    }

    // MARK: Save / Open / Reset (HTML draft files)

    /// Save the current draft as an HTML file (with embedded document data),
    /// letting the user choose the folder and filename.
    func saveDraft() {
        let panel = NSSavePanel()
        panel.title = "Save Draft"
        panel.nameFieldStringValue = draftFilename
        panel.allowedContentTypes = [.html]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try draftHTML().write(to: url, atomically: true, encoding: .utf8)
            statusMessage = "Draft saved"
        } catch {
            presentAlert(title: "Couldn\u{2019}t save draft", message: error.localizedDescription)
        }
    }

    /// Open a previously saved Byline draft HTML file and repopulate the fields.
    /// Files without Byline draft data are rejected with a warning.
    func openDraft() {
        let panel = NSOpenPanel()
        panel.title = "Open Draft"
        panel.allowedContentTypes = [.html]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            guard let decoded = Self.decodeDraft(from: content) else {
                presentAlert(
                    title: "Not a Byline draft",
                    message: "This HTML file doesn\u{2019}t contain Byline draft data, so its fields can\u{2019}t be loaded. Only drafts saved from Byline can be opened."
                )
                return
            }
            doc = decoded
            statusMessage = "Draft opened"
        } catch {
            presentAlert(title: "Couldn\u{2019}t open file", message: error.localizedDescription)
        }
    }

    func reset() {
        doc = Self.loadDefaults()
        statusMessage = "Reset to defaults"
    }

    /// Persist the current view (content + formatting) as the new default used
    /// by app launch, Reset to Defaults, and Clear All Fields.
    func setCurrentAsDefault() {
        guard let data = try? JSONEncoder().encode(doc) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultDocKey)
        statusMessage = "Saved current view as default"
    }

    /// Blank the content fields and set the date to today, keeping the default
    /// text for Eyebrow, Byline, the section headers, and Footer, plus the
    /// current theme/formatting.
    func clearAllFields() {
        let def = Self.loadDefaults()
        var d = doc // keep theme, previewMode, issue

        // Kept from defaults
        d.eyebrow = def.eyebrow
        d.byline = def.byline
        d.footer = def.footer
        d.sections = def.sections // restores section header names + visibility
        d.cta = def.cta           // keep the Call to Action invitation,
        d.ctaEmail = def.ctaEmail // email,
        d.ctaPhone = def.ctaPhone // and phone

        // Date -> today
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        d.date = f.string(from: Date())

        // Cleared content
        d.headline = ""
        d.hook = ""
        d.storyBody = ""
        d.maia = ""
        d.bottomLine = def.bottomLine.map { _ in .init(lead: "", sentence: "") }
        d.radar = def.radar.map { _ in .init(title: "", source: "", url: "", comment: "") }

        doc = d
        statusMessage = "Cleared all fields"
    }

    // MARK: Derived output

    var html: String { NewsletterRenderer.html(for: doc) }

    /// Final, email-ready filename.
    var exportFilename: String {
        "Weekly College Story - \(doc.date) - Final.html"
    }

    /// Draft filename: same base, "DRAFT <save date-time>" instead of "Final".
    var draftFilename: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH-mm"
        return "Weekly College Story - \(doc.date) - DRAFT \(f.string(from: Date())).html"
    }

    /// The rendered newsletter with the full document embedded as a hidden
    /// comment just inside <body>, so the draft round-trips losslessly.
    func draftHTML() -> String {
        let clean = html
        guard let data = try? JSONEncoder().encode(doc) else { return clean }
        let marker = "\n  <!-- \(Self.draftMarkerPrefix)\(data.base64EncodedString()) -->"
        var s = clean
        if let bodyStart = s.range(of: "<body"),
           let close = s[bodyStart.lowerBound...].firstIndex(of: ">") {
            s.insert(contentsOf: marker, at: s.index(after: close))
        }
        return s
    }

    /// Extracts and decodes the embedded document from a saved draft, or nil
    /// when the marker is missing or unreadable.
    static func decodeDraft(from content: String) -> NewsletterDocument? {
        guard let start = content.range(of: "<!-- \(draftMarkerPrefix)") else { return nil }
        let rest = content[start.upperBound...]
        guard let end = rest.range(of: "-->") else { return nil }
        let b64 = rest[rest.startIndex..<end.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: b64),
              let decoded = try? JSONDecoder().decode(NewsletterDocument.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: Array mutators

    func addBottomLine() {
        doc.bottomLine.append(.init(lead: "", sentence: ""))
    }

    func removeBottomLine(at index: Int) {
        guard doc.bottomLine.indices.contains(index) else { return }
        doc.bottomLine.remove(at: index)
    }

    func addRadar() {
        doc.radar.append(.init(title: "", source: "", url: "", comment: ""))
    }

    func removeRadar(at index: Int) {
        guard doc.radar.indices.contains(index) else { return }
        doc.radar.remove(at: index)
    }

    // MARK: Section helpers

    func sectionBinding(_ key: String) -> NewsletterDocument.SectionMeta {
        doc.sections[key] ?? .init(present: true, include: true, name: "")
    }

    func setSectionName(_ key: String, _ name: String) {
        doc.sections[key]?.name = name
    }

    func setSectionInclude(_ key: String, _ include: Bool) {
        doc.sections[key]?.include = include
    }
}
