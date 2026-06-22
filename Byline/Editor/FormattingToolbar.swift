import SwiftUI

/// The five-button formatting bar pinned to the top of the editor pane.
/// Acts on whichever multiline field is currently focused.
struct FormattingToolbar: View {
    @EnvironmentObject var focus: EditorFocusController

    var body: some View {
        HStack(spacing: 4) {
            toolButton("Subhead", help: "Make the current line a subhead (## )") {
                focus.setLinePrefix("## ")
            }
            toolButton("Body", help: "Make the current line a normal paragraph") {
                focus.setLinePrefix(nil)
            }
            Divider().frame(height: 16)
            toolButton("B", help: "Bold", bold: true) {
                focus.wrap("strong")
            }
            toolButton("I", help: "Italic", italic: true) {
                focus.wrap("em")
            }
            Divider().frame(height: 16)
            toolButton("Pull Quote", help: "Make the current line a pull quote (> )") {
                focus.setLinePrefix("> ")
            }

            Spacer()

            Text("Select text in a field, then apply")
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.69))
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color(white: 0.984))
        .overlay(Divider(), alignment: .bottom)
    }

    private func toolButton(_ label: String, help: String, bold: Bool = false, italic: Bool = false, action: @escaping () -> Void) -> some View {
        var text = Text(label)
            .font(.system(size: 13, weight: bold ? .heavy : .regular))
            .foregroundColor(Color(white: 0.27))
        if italic { text = text.italic() }
        return Button(action: action) {
            text
                .padding(.horizontal, 9)
                .frame(height: 28)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .help(help)
    }
}
