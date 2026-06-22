import SwiftUI

/// The left pane: pinned formatting toolbar over a scrolling form of all
/// labeled sections, matching the design's layout and order.
struct EditorPane: View {
    @EnvironmentObject var store: DocumentStore
    @EnvironmentObject var focus: EditorFocusController

    var body: some View {
        VStack(spacing: 0) {
            FormattingToolbar()
            ScrollView {
                VStack(spacing: 0) {
                    masthead
                    byline
                    if present("hook") { hookSection }
                    if present("bottomLine") { bottomLineSection }
                    if present("story") { storySection }
                    if present("maia") { maiaSection }
                    if present("radar") { radarSection }
                    if present("cta") { ctaSection }
                    footerSection
                    themeSection
                    Color.clear.frame(height: 18)
                }
            }
            .background(Color(white: 1.0))
        }
        .background(Color(white: 1.0))
    }

    // MARK: Sections

    private var masthead: some View {
        SectionCard {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    FieldLabel(text: "Eyebrow")
                    TextField("", text: $store.doc.eyebrow)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                }
                VStack(alignment: .leading, spacing: 7) {
                    FieldLabel(text: "Date")
                    DatePicker("", selection: dateBinding, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.field)
                }
                .frame(width: 170)
            }
            VStack(alignment: .leading, spacing: 7) {
                FieldLabel(text: "Headline")
                TextField("", text: $store.doc.headline)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 19, weight: .semibold))
            }
        }
    }

    private var byline: some View {
        SectionCard {
            FieldLabel(text: "From / Byline")
            TextField("Author name", text: $store.doc.byline.author)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
            HStack(spacing: 18) {
                Toggle("Author", isOn: $store.doc.byline.showAuthor)
                    .toggleStyle(.checkbox)
                Toggle("Date", isOn: $store.doc.byline.showDate)
                    .toggleStyle(.checkbox)
            }
            .font(.system(size: 13))
        }
    }

    private var hookSection: some View {
        SectionCard {
            SectionHeaderBar(title: "Hook", name: nameBinding("hook"),
                             include: includeBinding("hook"), bordered: false)
            RichTextEditor(text: $store.doc.hook, minHeight: 80, focus: focus)
                .frame(height: 80)
        }
    }

    private var bottomLineSection: some View {
        SectionCard {
            SectionHeaderBar(title: "The Bottom Line", name: nameBinding("bottomLine"),
                             include: includeBinding("bottomLine"), bordered: true)
            BottomLineEditor(items: $store.doc.bottomLine,
                             onAdd: store.addBottomLine,
                             onRemove: store.removeBottomLine)
        }
    }

    private var storySection: some View {
        SectionCard {
            SectionHeaderBar(title: "Story Body", name: nameBinding("story"),
                             include: includeBinding("story"), bordered: false)
            RichTextEditor(text: $store.doc.storyBody, minHeight: 220, focus: focus)
                .frame(height: 220)
            HStack(spacing: 4) {
                Text("Start a line with")
                Text("##").fontWeight(.bold)
                Text("for a subhead or")
                Text(">").fontWeight(.bold)
                Text("for a pull quote.")
            }
            .font(.system(size: 11.5))
            .foregroundColor(Color(white: 0.68))
        }
    }

    private var maiaSection: some View {
        SectionCard {
            SectionHeaderBar(title: "MAIA\u{2019}s Viewpoint", name: nameBinding("maia"),
                             include: includeBinding("maia"), bordered: true)
            RichTextEditor(text: $store.doc.maia, minHeight: 100, focus: focus)
                .frame(height: 100)
        }
    }

    private var radarSection: some View {
        SectionCard {
            SectionHeaderBar(title: "On My Radar", name: nameBinding("radar"),
                             include: includeBinding("radar"), bordered: true)
            RadarEditor(items: $store.doc.radar,
                        onAdd: store.addRadar,
                        onRemove: store.removeRadar)
        }
    }

    private var ctaSection: some View {
        SectionCard {
            SectionHeaderBar(title: "Call to Action", name: nameBinding("cta"),
                             include: includeBinding("cta"), bordered: false)
            RichTextEditor(text: $store.doc.cta, minHeight: 80, focus: focus)
                .frame(height: 80)
            HStack(spacing: 8) {
                TextField("Email", text: $store.doc.ctaEmail)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#0088CB"))
                TextField("Phone", text: $store.doc.ctaPhone)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13))
                    .frame(width: 140)
            }
        }
    }

    private var footerSection: some View {
        SectionCard {
            FieldLabel(text: "Footer")
            TextField("", text: $store.doc.footer)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
        }
    }

    private var themeSection: some View {
        SectionCard {
            FieldLabel(text: "Theme & colors")
            VStack(spacing: 9) {
                ThemeRow(label: "Page background", hex: $store.doc.theme.pageBg)
                ThemeRow(label: "Accent & rules", hex: $store.doc.theme.accent)
                ThemeRow(label: "Title color", hex: $store.doc.theme.heading)
                ThemeRow(label: "Body text", hex: $store.doc.theme.body)
                ThemeRow(label: "Links", hex: $store.doc.theme.link)
            }
        }
    }

    // MARK: Binding helpers

    private func present(_ key: String) -> Bool {
        store.doc.sections[key]?.present ?? true
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                f.timeZone = TimeZone(identifier: "UTC")
                return f.date(from: store.doc.date) ?? Date()
            },
            set: {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd"
                f.timeZone = TimeZone(identifier: "UTC")
                store.doc.date = f.string(from: $0)
            }
        )
    }

    private func nameBinding(_ key: String) -> Binding<String> {
        Binding(
            get: { store.doc.sections[key]?.name ?? "" },
            set: { store.doc.sections[key]?.name = $0 }
        )
    }

    private func includeBinding(_ key: String) -> Binding<Bool> {
        Binding(
            get: { store.doc.sections[key]?.include ?? true },
            set: { store.doc.sections[key]?.include = $0 }
        )
    }
}
