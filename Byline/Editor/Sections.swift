import SwiftUI

// MARK: - Shared style helpers

extension View {
    func fieldLabel() -> some View {
        self.font(.system(size: 11, weight: .semibold))
            .textCase(.uppercase)
            .kerning(0.5)
            .foregroundColor(Color(white: 0.6))
    }
}

/// A small uppercase label above a field.
struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text).fieldLabel()
    }
}

/// A toggleable, renamable section header row: editable name + "Show" checkbox.
struct SectionHeaderBar: View {
    let title: String
    @Binding var name: String
    @Binding var include: Bool
    /// Borderless eyebrow style (hook/story/cta) vs. bordered "Section header"
    /// style (bottom line / MAIA / radar), matching the design.
    var bordered: Bool

    var body: some View {
        HStack(spacing: 10) {
            if bordered {
                TextField("Section header", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, weight: .semibold))
            } else {
                TextField(title, text: $name)
                    .textFieldStyle(.plain)
                    .fieldLabel()
            }
            Toggle("Show", isOn: $include)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.6))
                .fixedSize()
        }
    }
}

/// Standard padded card wrapper used by every editor section.
struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        Divider()
    }
}

// MARK: - Bottom line rows

struct BottomLineEditor: View {
    @Binding var items: [NewsletterDocument.BottomLineItem]
    var onAdd: () -> Void
    var onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                HStack(spacing: 8) {
                    TextField("Lead-in", text: $items[index].lead)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 150)
                    TextField("Sentence", text: $items[index].sentence)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    Button {
                        onRemove(index)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Delete line")
                }
            }
            Button(action: onAdd) {
                Text("+ Add line")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#0088CB"))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Radar cards

struct RadarEditor: View {
    @Binding var items: [NewsletterDocument.RadarItem]
    var onAdd: () -> Void
    var onRemove: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Title", text: $items[index].title)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, weight: .semibold))
                        Button {
                            onRemove(index)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.72))
                        }
                        .buttonStyle(.plain)
                        .help("Remove")
                    }
                    TextField("Source", text: $items[index].source)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    TextField("URL", text: $items[index].url)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#0088CB"))
                    TextField("Comment", text: $items[index].comment, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .lineLimit(2...4)
                }
                .padding(12)
                .background(Color(white: 0.988))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(white: 0.9), lineWidth: 1)
                )
            }
            Button(action: onAdd) {
                Text("+ Add item")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#0088CB"))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Theme rows

struct ThemeRow: View {
    let label: String
    @Binding var hex: String

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: hex) },
            set: { hex = $0.hexString }
        )
    }

    var body: some View {
        HStack(spacing: 11) {
            ColorPicker("", selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.33))
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("", text: $hex)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .frame(width: 90)
        }
    }
}
