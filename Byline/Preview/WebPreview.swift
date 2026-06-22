import SwiftUI
import WebKit

/// Renders the generated newsletter HTML in a WKWebView.
///
/// The first render loads the full document. Subsequent renders swap the
/// document body in place via JavaScript instead of reloading the page, so the
/// reader's scroll position is preserved while edits stream in.
struct WebPreview: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.lastHTML = html
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let c = context.coordinator
        guard c.lastHTML != html else { return }
        c.lastHTML = html
        if c.didLoad {
            c.applyInPlace(webView, html)
        } else {
            c.pendingHTML = html
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML = ""
        var didLoad = false
        var pendingHTML: String?

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            didLoad = true
            if let pending = pendingHTML {
                pendingHTML = nil
                applyInPlace(webView, pending)
            }
        }

        /// Replace the body content and its inline style (page background) of
        /// the already-loaded document without navigating, keeping scroll.
        func applyInPlace(_ webView: WKWebView, _ html: String) {
            guard let data = try? JSONEncoder().encode(html),
                  let literal = String(data: data, encoding: .utf8) else { return }
            let js = """
            (function(){
              try {
                var d = new DOMParser().parseFromString(\(literal), 'text/html');
                document.body.setAttribute('style', d.body.getAttribute('style') || '');
                document.body.innerHTML = d.body.innerHTML;
              } catch (e) {}
            })();
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
    }
}
