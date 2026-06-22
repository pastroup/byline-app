import Foundation

/// Renders a `NewsletterDocument` into a single self-contained, email-safe
/// HTML file built on the brand's 600px `<table>` scaffold. The same output
/// feeds both the live WKWebView preview and Copy / Export (true WYSIWYG).
///
/// Theme colors are wired into the fixed brand roles; the defaults reproduce
/// the brand template exactly. Editable section names drive the headers that
/// the design renders (Bottom Line, MAIA, Radar). Hook, Story, and CTA carry
/// no rendered header, matching the design.
enum NewsletterRenderer {

    // MARK: Public entry point

    /// - Parameter mobile: when true, bakes the responsive mobile rules in
    ///   unconditionally so the on-screen preview matches a phone (macOS
    ///   WKWebView does not emulate a mobile viewport). Export always uses
    ///   `mobile: false`, keeping the real `@media` query for mail clients.
    static func html(for doc: NewsletterDocument, mobile: Bool = false) -> String {
        let t = doc.theme
        let pageBg = t.pageBg.isEmpty ? "#e7ecf0" : t.pageBg
        let accent = t.accent.isEmpty ? "#F4A01A" : t.accent
        let heading = t.heading.isEmpty ? "#000000" : t.heading
        let body = t.body.isEmpty ? "#434343" : t.body
        let link = t.link.isEmpty ? "#0088CB" : t.link

        var rows = ""

        // Masthead -----------------------------------------------------------
        let bylineLine = bylineText(doc)
        var masthead = """
              <tr>
                <td class="px" style="padding:30px 40px 0 40px;">
                  <p style="margin:0 0 6px 0; font-family:Georgia,'Times New Roman',serif; font-size:13px; letter-spacing:2px; text-transform:uppercase; font-weight:bold; color:\(accent);">\(inline(doc.eyebrow))</p>
                  <h1 class="h1" style="margin:0 0 14px 0; font-family:Georgia,'Times New Roman',serif; font-size:28px; line-height:34px; font-weight:bold; color:\(heading);">\(inline(doc.headline))</h1>
        """
        if !bylineLine.isEmpty {
            masthead += """

                  <p style="margin:0; padding-bottom:18px; border-bottom:2px solid \(accent); font-family:Arial,sans-serif; font-size:13px; color:#BEBEBE;">\(bylineLine)</p>
            """
        }
        masthead += """

                </td>
              </tr>
        """
        rows += masthead

        // Hook ---------------------------------------------------------------
        if isShown(doc, "hook"), !doc.hook.trimmed.isEmpty {
            rows += """

              <tr>
                <td class="px" style="padding:24px 40px 0 40px;">
                  <p style="margin:0; font-family:Arial,sans-serif; font-size:16px; line-height:25px; color:\(body);">\(inline(doc.hook))</p>
                </td>
              </tr>
        """
        }

        // The Bottom Line ----------------------------------------------------
        if isShown(doc, "bottomLine"), !doc.bottomLine.isEmpty {
            var bullets = ""
            for item in doc.bottomLine {
                bullets += """

                      <tr>
                        <td valign="top" width="17" style="padding:7px 11px 11px 0;"><div style="width:6px; height:6px; background-color:\(accent); font-size:0; line-height:0;">&nbsp;</div></td>
                        <td valign="top" style="padding:0 0 11px 0; font-family:Arial,sans-serif; font-size:15px; line-height:24px; color:\(body);"><strong style="color:#000000;">\(inline(item.lead))</strong> \(inline(item.sentence))</td>
                      </tr>
            """
            }
            rows += """

              <tr>
                <td class="px" style="padding:24px 40px 0 40px;">
                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#fafafa; border-radius:4px;"><tr>
                    <td style="padding:20px 22px;">
                      <p style="margin:0 0 13px 0; font-family:Georgia,'Times New Roman',serif; font-size:13px; font-weight:bold; letter-spacing:1px; text-transform:uppercase; color:\(heading);">\(inline(sectionName(doc, "bottomLine")))</p>
                      <table role="presentation" width="100%" cellpadding="0" cellspacing="0">\(bullets)
                      </table>
                    </td>
                  </tr></table>
                </td>
              </tr>
        """
        }

        // Story --------------------------------------------------------------
        if isShown(doc, "story"), !doc.storyBody.trimmed.isEmpty {
            let storyHTML = renderStory(doc.storyBody, accent: accent, body: body)
            rows += """

              <tr>
                <td class="px" style="padding:26px 40px 0 40px;">
        \(storyHTML)
                </td>
              </tr>
        """
        }

        // MAIA's Viewpoint ---------------------------------------------------
        if isShown(doc, "maia"), !doc.maia.trimmed.isEmpty {
            rows += """

              <tr>
                <td class="px" style="padding:22px 40px 0 40px;">
                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#FFF9F0; border:1px solid \(accent); border-radius:4px;"><tr>
                    <td style="padding:18px 20px;">
                      <p style="margin:0 0 9px 0; font-family:Georgia,'Times New Roman',serif; font-size:13px; font-weight:bold; letter-spacing:1px; text-transform:uppercase; color:\(heading);">\(inline(sectionName(doc, "maia")))</p>
                      <p style="margin:0; font-family:Arial,sans-serif; font-size:15px; line-height:24px; color:\(body);">\(inline(doc.maia))</p>
                    </td>
                  </tr></table>
                </td>
              </tr>
        """
        }

        // On My Radar --------------------------------------------------------
        if isShown(doc, "radar"), !doc.radar.isEmpty {
            var items = ""
            for it in doc.radar {
                let url = it.url.trimmed.isEmpty ? "#" : attr(it.url)
                let sourcePart = it.source.trimmed.isEmpty
                    ? ""
                    : " <span style=\"color:#BEBEBE; font-size:13px;\">&middot; \(inline(it.source))</span>"
                items += """

                  <p style="margin:0 0 3px 0; font-family:Arial,sans-serif; font-size:16px; line-height:22px;"><a href="\(url)" style="color:\(link); font-weight:bold; text-decoration:none;">\(inline(it.title))</a>\(sourcePart)</p>
                  <p style="margin:0 0 18px 0; font-family:Arial,sans-serif; font-size:15px; line-height:22px; font-style:italic; color:\(body);">\(inline(it.comment))</p>
            """
            }
            rows += """

              <tr>
                <td class="px" style="padding:28px 40px 0 40px;">
                  <p style="margin:0 0 16px 0; padding-top:18px; border-top:3px solid \(accent); font-family:Georgia,'Times New Roman',serif; font-size:21px; font-weight:bold; color:\(heading);">\(inline(sectionName(doc, "radar")))</p>\(items)
                </td>
              </tr>
        """
        }

        // CTA ----------------------------------------------------------------
        if isShown(doc, "cta"), !doc.cta.trimmed.isEmpty {
            let email = doc.ctaEmail.trimmed
            let phone = doc.ctaPhone.trimmed
            var contacts = ""
            if !email.isEmpty {
                contacts += "<a href=\"mailto:\(attr(email))\" style=\"color:\(link); text-decoration:none;\">\(inline(email))</a>"
            }
            if !email.isEmpty, !phone.isEmpty {
                contacts += " &nbsp;|&nbsp; "
            }
            if !phone.isEmpty {
                contacts += inline(phone)
            }
            let contactsRow = contacts.isEmpty ? "" : """

                      <p style="margin:14px 0 0 0; font-family:Arial,sans-serif; font-size:14px; font-weight:bold; color:#000000;">\(contacts)</p>
            """
            rows += """

              <tr>
                <td class="px" style="padding:28px 40px 32px 40px;">
                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#FFF9F0; border:1px solid \(accent); border-radius:6px;"><tr>
                    <td align="center" style="padding:26px 28px;">
                      <p style="margin:0; font-family:Arial,sans-serif; font-size:16px; line-height:24px; color:\(body);">\(inline(doc.cta))</p>\(contactsRow)
                    </td>
                  </tr></table>
                </td>
              </tr>
        """
        }

        // Footer -------------------------------------------------------------
        if !doc.footer.trimmed.isEmpty {
            rows += """

              <tr>
                <td style="padding:22px 40px 30px 40px; border-top:1px solid #e6e3dd;">
                  <p style="margin:0; font-family:Arial,sans-serif; font-size:12px; line-height:18px; color:#BEBEBE; text-align:center;">\(inline(doc.footer))</p>
                </td>
              </tr>
        """
        }

        // Document scaffold --------------------------------------------------
        let title = "Weekly College Story #\(inline(doc.issue))"
        // Preview-only: force the mobile layout (the classes already exist on
        // the container/px/h1 elements). Lives inside <body> so it survives the
        // preview's in-place DOM updates.
        let mobileOverride = mobile ? """

          <style>
            .container { width:380px !important; max-width:380px !important; }
            .px { padding-left:22px !important; padding-right:22px !important; }
            .h1 { font-size:24px !important; line-height:30px !important; }
          </style>
        """ : ""
        return """
        <!DOCTYPE html>
        <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <meta http-equiv="X-UA-Compatible" content="IE=edge">
          <title>\(title)</title>
          <style type="text/css">
            body { margin:0; padding:0; background-color:\(pageBg); -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; }
            table { border-collapse:collapse; }
            img { border:0; line-height:100%; outline:none; text-decoration:none; }
            a { color:\(link); }
            @media only screen and (max-width:620px) {
              .container { width:100% !important; }
              .px { padding-left:22px !important; padding-right:22px !important; }
              .h1 { font-size:24px !important; line-height:30px !important; }
            }
          </style>
        </head>
        <body style="margin:0; padding:0; background-color:\(pageBg);">\(mobileOverride)

          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:\(pageBg);">
            <tr>
              <td align="center" style="padding:24px 12px;">

                <table role="presentation" class="container" width="600" cellpadding="0" cellspacing="0" style="width:600px; max-width:600px; background-color:#ffffff;">

                  <!-- Gold top bar -->
                  <tr><td style="height:6px; background-color:\(accent); font-size:0; line-height:0;">&nbsp;</td></tr>
        \(rows)
                </table>
              </td>
            </tr>
          </table>
        </body>
        </html>
        """
    }

    // MARK: - Section helpers

    private static func isShown(_ doc: NewsletterDocument, _ key: String) -> Bool {
        guard let s = doc.sections[key] else { return true }
        return s.present && s.include
    }

    private static func sectionName(_ doc: NewsletterDocument, _ key: String) -> String {
        doc.sections[key]?.name ?? ""
    }

    private static func bylineText(_ doc: NewsletterDocument) -> String {
        var parts: [String] = []
        if doc.byline.showAuthor, !doc.byline.author.trimmed.isEmpty {
            parts.append(inline(doc.byline.author))
        }
        if doc.byline.showDate {
            let d = formatDate(doc.date)
            if !d.isEmpty { parts.append(esc(d)) }
        }
        return parts.joined(separator: " &nbsp;|&nbsp; ")
    }

    // MARK: - Story parsing

    /// Splits on blank lines: `## ` -> subhead, `> ` -> pull quote, else paragraph.
    private static func renderStory(_ raw: String, accent: String, body: String) -> String {
        let blocks = raw.replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var out = ""
        for block in blocks {
            if block.hasPrefix("## ") {
                let text = String(block.dropFirst(3))
                out += """

                  <p style="margin:0 0 10px 0; font-family:Georgia,'Times New Roman',serif; font-size:17px; font-weight:bold; color:#666666;">\(inline(text))</p>
            """
            } else if block.hasPrefix("> ") {
                let text = String(block.dropFirst(2))
                out += """

                  <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                    <tr><td height="6" style="font-size:0; line-height:0;">&nbsp;</td></tr>
                    <tr><td style="padding:0 0 0 20px; border-left:4px solid \(accent);">
                      <p style="margin:0; font-family:Georgia,'Times New Roman',serif; font-size:19px; line-height:28px; font-style:italic; color:#000000;">\(inline(text))</p>
                    </td></tr>
                    <tr><td height="20" style="font-size:0; line-height:0;">&nbsp;</td></tr>
                  </table>
            """
            } else {
                out += """

                  <p style="margin:0 0 16px 0; font-family:Arial,sans-serif; font-size:16px; line-height:25px; color:\(body);">\(inline(block))</p>
            """
            }
        }
        return out
    }

    // MARK: - Inline text processing

    /// Full inline pipeline: scrub em dashes, escape, restore allowed tags,
    /// encode curly quotes, convert newlines to <br>.
    static func inline(_ text: String) -> String {
        var s = scrubDashes(text)
        s = esc(s)
        s = restoreTags(s)
        s = encodeCurlyQuotes(s)
        s = s.replacingOccurrences(of: "\n", with: "<br>")
        return s
    }

    /// Hard brand rule: no em dashes anywhere. Replaces the em dash (and its
    /// HTML entities) and the `--` shorthand with a comma. En dashes are left
    /// intact since they are legitimate in ranges (e.g. "2010\u{2013}2020").
    static func scrubDashes(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "&mdash;", with: ", ")
        s = s.replacingOccurrences(of: "&#8212;", with: ", ")
        // em dash (U+2014), with any surrounding whitespace collapsed.
        // Interpolate the literal character so ICU matches it directly.
        s = regexReplace(s, pattern: "\\s*\u{2014}\\s*", with: ", ")
        // double hyphen
        s = regexReplace(s, pattern: "\\s*--\\s*", with: ", ")
        return s
    }

    private static func esc(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "<", with: "&lt;")
        s = s.replacingOccurrences(of: ">", with: "&gt;")
        return s
    }

    /// Re-allows the five formatting tags the toolbar inserts and maps them to
    /// the brand's styled output (`<strong style="color:#000000;">`, `<em>`).
    private static func restoreTags(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "&lt;strong&gt;", with: "<strong style=\"color:#000000;\">")
        s = s.replacingOccurrences(of: "&lt;b&gt;", with: "<strong style=\"color:#000000;\">")
        s = s.replacingOccurrences(of: "&lt;/strong&gt;", with: "</strong>")
        s = s.replacingOccurrences(of: "&lt;/b&gt;", with: "</strong>")
        s = s.replacingOccurrences(of: "&lt;em&gt;", with: "<em>")
        s = s.replacingOccurrences(of: "&lt;i&gt;", with: "<em>")
        s = s.replacingOccurrences(of: "&lt;/em&gt;", with: "</em>")
        s = s.replacingOccurrences(of: "&lt;/i&gt;", with: "</em>")
        return s
    }

    private static func encodeCurlyQuotes(_ text: String) -> String {
        var s = text
        s = s.replacingOccurrences(of: "\u{2019}", with: "&rsquo;")
        s = s.replacingOccurrences(of: "\u{2018}", with: "&lsquo;")
        s = s.replacingOccurrences(of: "\u{201C}", with: "&ldquo;")
        s = s.replacingOccurrences(of: "\u{201D}", with: "&rdquo;")
        return s
    }

    /// Escapes a value destined for an HTML attribute (href / mailto).
    private static func attr(_ text: String) -> String {
        var s = scrubDashes(text)
        s = s.replacingOccurrences(of: "&", with: "&amp;")
        s = s.replacingOccurrences(of: "\"", with: "&quot;")
        s = s.replacingOccurrences(of: "<", with: "&lt;")
        s = s.replacingOccurrences(of: ">", with: "&gt;")
        return s
    }

    // MARK: - Utilities

    static func formatDate(_ ymd: String) -> String {
        let parts = ymd.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2]),
              (1...12).contains(m) else { return ymd }
        let months = ["January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        return "\(months[m - 1]) \(d), \(y)"
    }

    private static func regexReplace(_ text: String, pattern: String, with replacement: String) -> String {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return re.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
