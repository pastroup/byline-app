# Byline

A native macOS app that turns a short story into a finished, email-ready HTML
newsletter matching the MAIA brand template. Write an issue in the left pane and
see the styled, email-safe HTML live on the right; copy or export it with one click.

- **Native Swift + SwiftUI**, single window, no Electron / web wrapper.
- **Zero third-party dependencies** — only Apple frameworks (SwiftUI, AppKit, WebKit).
- **Universal** (Apple Silicon + Intel), **macOS 13 (Ventura)** or later.
- Release build is ~1.6 MB with no bundled runtimes.

## Build & run

Requires Xcode 16 or later (the project uses file-system-synchronized groups).

```sh
open Byline.xcodeproj      # then press ⌘R
```

Or from the command line:

```sh
xcodebuild -project Byline.xcodeproj -scheme Byline -configuration Debug \
  -destination 'platform=macOS' build
```

The project is ad-hoc signed ("Sign to Run Locally"), so it builds and runs with
no Apple Developer account or team setup.

## Archive a distributable `.app`

```sh
xcodebuild -project Byline.xcodeproj -scheme Byline -configuration Release \
  -archivePath build/Byline.xcarchive archive

# The .app is inside the archive:
open build/Byline.xcarchive/Products/Applications/
```

For distribution outside your own machine, open the project in Xcode, set your
team under **Signing & Capabilities**, and use **Product ▸ Archive** to sign and
notarize.

## How it works

| Area | Notes |
| --- | --- |
| Left pane | Scrolling form of labeled sections + a pinned 5-button formatting toolbar (Subhead, Body, Bold, Italic, Pull Quote). |
| Right pane | `WKWebView` rendering the generated newsletter, debounced ~300 ms on edits. |
| Window toolbar | Save / Open / Reset, a Desktop (600px) / Mobile preview toggle, **Copy HTML**, and **Export HTML…**. |
| Sections | Hook, The Bottom Line, Story, MAIA's Viewpoint, On My Radar, and Call to Action can each be renamed and shown/hidden. |
| Story formatting | Markdown-style: `## ` for a subhead, `> ` for a pull quote, blank lines separate paragraphs; `<strong>` / `<em>` for inline emphasis (inserted by the toolbar). |
| Theme | The Theme & colors editor maps onto the template's color roles (page background, accent, title, body, links). Defaults reproduce the brand exactly. |
| Save / Open | A single-slot JSON draft kept in `UserDefaults` (`byline:doc`). Export writes a standalone `.html` file. |

### Output

Copy / Export produce a **single self-contained, email-safe HTML file** built on
the brand's 600px `<table>` scaffold with inline styles only — no external CSS or
JavaScript. The same renderer drives the live preview, so what you see is what you
send. Em dashes are stripped automatically (a hard brand rule), curly quotes are
encoded as entities, and the export is suggested as
`Weekly College Story #<issue> - FINAL.html`.

## Project layout

```
Byline.xcodeproj/
Byline/
  BylineApp.swift            App entry point, single window
  ContentView.swift          Split view, window toolbar, debounced preview
  Models/Document.swift       Document model + sample defaults
  Render/NewsletterRenderer.swift  Document -> email-safe HTML
  Store/DocumentStore.swift   Live state, save/open/reset, export
  Editor/                     Editor pane, sections, rich-text editor, toolbar
  Preview/WebPreview.swift    WKWebView wrapper
  Info.plist, Assets.xcassets
```

## Sandboxing

The app ships non-sandboxed so the save panel and clipboard work with no extra
setup. To sandbox it, add an entitlements file with
`com.apple.security.app-sandbox` and `com.apple.security.files.user-selected.read-write`,
then set `CODE_SIGN_ENTITLEMENTS` for the target.
