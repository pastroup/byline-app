import Foundation

// MARK: - Document model

/// The full editable newsletter document. Codable so it can be persisted as
/// a single-slot JSON draft (mirrors the design's localStorage `byline:doc`).
struct NewsletterDocument: Codable, Equatable {

    // Masthead
    var eyebrow: String
    var issue: String          // kept in model (no editor field); used for <title>
    var date: String           // "yyyy-MM-dd"
    var headline: String

    // Byline
    var byline: Byline

    // Body content
    var hook: String
    var bottomLine: [BottomLineItem]
    var storyBody: String      // ## subhead / > quote / blank-line paragraphs, <strong>/<em> inline
    var maia: String
    var radar: [RadarItem]
    var cta: String
    var ctaEmail: String
    var ctaPhone: String
    var footer: String

    // Section visibility / naming
    var sections: [String: SectionMeta]

    // Theme
    var theme: Theme

    // View state (persisted with the draft, like the design)
    var previewMode: PreviewMode

    // MARK: Nested types

    struct Byline: Codable, Equatable {
        var author: String
        var showAuthor: Bool
        var showDate: Bool
    }

    struct BottomLineItem: Codable, Equatable, Identifiable {
        var id = UUID()
        var lead: String
        var sentence: String

        enum CodingKeys: String, CodingKey { case lead, sentence }
    }

    struct RadarItem: Codable, Equatable, Identifiable {
        var id = UUID()
        var title: String
        var source: String
        var url: String
        var comment: String

        enum CodingKeys: String, CodingKey { case title, source, url, comment }
    }

    struct SectionMeta: Codable, Equatable {
        var present: Bool
        var include: Bool
        var name: String
    }

    struct Theme: Codable, Equatable {
        var pageBg: String
        var accent: String
        var heading: String
        var body: String
        var link: String
    }

    enum PreviewMode: String, Codable, Equatable {
        case desktop
        case mobile
    }

    /// Section keys in display order.
    static let sectionOrder = ["hook", "bottomLine", "story", "maia", "radar", "cta"]
}

// MARK: - Sample defaults (from the Claude Design getDefaults())

extension NewsletterDocument {
    static func defaults() -> NewsletterDocument {
        NewsletterDocument(
            eyebrow: "The Weekly College Story",
            issue: "47",
            date: "2026-06-19",
            headline: "What \u{2018}Demonstrated Interest\u{2019} Actually Means Now",
            byline: Byline(author: "Nick Kruter, MAIA Education", showAuthor: true, showDate: true),
            hook: "Every spring a parent asks me the same question: does it really matter if my kid opens the college\u{2019}s emails? For years I called it minor. I have changed my answer.",
            bottomLine: [
                BottomLineItem(lead: "Open the emails.", sentence: "Engagement is logged, and silence is the loudest signal you can send."),
                BottomLineItem(lead: "Pick your real ten.", sentence: "Spread thin across thirty schools and every signal gets diluted."),
                BottomLineItem(lead: "Reply like a person.", sentence: "Two honest lines to an admissions officer outweigh a summer tour."),
                BottomLineItem(lead: "Fake nothing.", sentence: "Manufactured interest reads as manufactured. They can tell."),
            ],
            storyBody: """
            Demonstrated interest used to be a footnote. A college might note whether you visited campus or opened a few emails, then file it away. Today, with application volume up and yield harder to predict, that footnote has moved closer to the headline.

            ## What schools actually track

            Most admissions offices now log a quiet trail of signals: whether you open their emails, click into the portal, attend a virtual session, or reply to outreach. None of it is secret, but very little of it is advertised.

            > The student who opens every email can read as more interested than the one who toured in July and then went silent.

            The takeaway is not to game the system. It is to be deliberate about the handful of schools that genuinely matter to you, and to let your attention reflect that.
            """,
            maia: "I keep one rule with families: interest you have to fake is interest you do not need. The schools worth your energy are the ones where paying attention feels natural. Start there, and the signals take care of themselves.",
            radar: [
                RadarItem(title: "Who Gets In and Why", source: "Jeffrey Selingo", url: "#", comment: "Still the clearest window into how yield and interest shape decisions."),
                RadarItem(title: "The Admissions Beat", source: "Substack", url: "#", comment: "A weekly read for the data behind the headlines."),
            ],
            cta: "Reach out to discuss how I can help design your student\u{2019}s summer so the fall is manageable. <strong>I\u{2019}d love to hear from you.</strong>",
            ctaEmail: "nick@maiaeducation.com",
            ctaPhone: "212.426.3742",
            footer: "MAIA Education Resource Center  |  maiaeducation.com",
            sections: [
                "hook":       SectionMeta(present: true, include: true, name: "Hook"),
                "bottomLine": SectionMeta(present: true, include: true, name: "The Bottom Line"),
                "story":      SectionMeta(present: true, include: true, name: "Story Body"),
                "maia":       SectionMeta(present: true, include: true, name: "MAIA\u{2019}s Viewpoint"),
                "radar":      SectionMeta(present: true, include: true, name: "On My Radar"),
                "cta":        SectionMeta(present: true, include: true, name: "Call to Action"),
            ],
            theme: Theme(pageBg: "#e7ecf0", accent: "#F4A01A", heading: "#F4A01A", body: "#434343", link: "#0088CB"),
            previewMode: .desktop
        )
    }
}
