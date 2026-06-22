import SwiftUI
import AppKit

/// Tracks which multiline editor is currently active so the formatting toolbar
/// can apply to "whichever field is focused" (mirrors the design's `_active`).
final class EditorFocusController: ObservableObject {
    weak var active: RichTextEditor.Coordinator?

    func wrap(_ tag: String) { active?.wrap(tag) }
    func setLinePrefix(_ prefix: String?) { active?.setLinePrefix(prefix) }
}

/// An NSTextView that reports when it becomes first responder.
final class FocusableTextView: NSTextView {
    var onFocus: (() -> Void)?

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { onFocus?() }
        return ok
    }
}

/// Plain-text multiline editor backed by NSTextView, with a two-way String
/// binding. Exposes `wrap` / `setLinePrefix` to the focus controller.
struct RichTextEditor: NSViewRepresentable {
    @Binding var text: String
    var minHeight: CGFloat = 120
    let focus: EditorFocusController

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, focus: focus)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.borderType = .lineBorder
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = true
        scroll.autohidesScrollers = true

        let tv = FocusableTextView()
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.font = NSFont.systemFont(ofSize: 13)
        tv.textColor = NSColor.textColor
        tv.textContainerInset = NSSize(width: 6, height: 8)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.string = text
        tv.onFocus = { [weak coordinator = context.coordinator] in
            coordinator?.becameActive()
        }

        context.coordinator.textView = tv
        scroll.documentView = tv
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.text = $text
        guard let tv = scroll.documentView as? NSTextView else { return }
        if tv.string != text {
            let sel = tv.selectedRange()
            tv.string = text
            // keep caret in range after external replacement
            let len = (tv.string as NSString).length
            tv.setSelectedRange(NSRange(location: min(sel.location, len), length: 0))
        }
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        let focus: EditorFocusController

        init(text: Binding<String>, focus: EditorFocusController) {
            self.text = text
            self.focus = focus
        }

        func becameActive() {
            focus.active = self
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            text.wrappedValue = tv.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            becameActive()
        }

        // MARK: Formatting operations

        private func ensureFirstResponder(_ tv: NSTextView) {
            if let win = tv.window, win.firstResponder !== tv {
                win.makeFirstResponder(tv)
            }
        }

        /// Wrap the current selection in <tag>…</tag>.
        func wrap(_ tag: String) {
            guard let tv = textView else { return }
            ensureFirstResponder(tv)
            let ns = tv.string as NSString
            let range = tv.selectedRange()
            let selected = ns.substring(with: range)
            let open = "<\(tag)>"
            let close = "</\(tag)>"
            let replacement = open + selected + close
            if tv.shouldChangeText(in: range, replacementString: replacement) {
                tv.replaceCharacters(in: range, with: replacement)
                tv.didChangeText()
            }
            let newStart = range.location + (open as NSString).length
            tv.setSelectedRange(NSRange(location: newStart, length: (selected as NSString).length))
            text.wrappedValue = tv.string
        }

        /// Set (or with nil, clear) a line-level Markdown prefix on the
        /// selected line(s): "## " for subhead, "> " for pull quote.
        func setLinePrefix(_ prefix: String?) {
            guard let tv = textView else { return }
            ensureFirstResponder(tv)
            let ns = tv.string as NSString
            let lineRange = ns.lineRange(for: tv.selectedRange())
            var lineText = ns.substring(with: lineRange)

            var trailing = ""
            if lineText.hasSuffix("\n") {
                trailing = "\n"
                lineText.removeLast()
            }

            var stripped = lineText
            for marker in ["## ", "> "] where stripped.hasPrefix(marker) {
                stripped = String(stripped.dropFirst(marker.count))
                break
            }

            let newLine = (prefix ?? "") + stripped + trailing
            if tv.shouldChangeText(in: lineRange, replacementString: newLine) {
                tv.replaceCharacters(in: lineRange, with: newLine)
                tv.didChangeText()
            }
            let caret = lineRange.location + (newLine as NSString).length - (trailing as NSString).length
            tv.setSelectedRange(NSRange(location: caret, length: 0))
            text.wrappedValue = tv.string
        }
    }
}
