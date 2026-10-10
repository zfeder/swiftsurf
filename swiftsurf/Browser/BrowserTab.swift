//
//  BrowserTab.swift
//  swiftsurf
//

import AppKit
import Observation
import WebKit

/// A JavaScript `alert`, `confirm` or `prompt` waiting for the user's answer.
struct JavaScriptDialog: Identifiable {
    enum Kind: Equatable {
        case alert
        case confirm
        case prompt(defaultText: String)
    }

    let id = UUID()
    let kind: Kind
    let message: String
    let host: String
    /// Called once with whether the user accepted, plus the entered text for prompts.
    let complete: (_ accepted: Bool, _ text: String?) -> Void
}

@Observable
final class BrowserTab: Identifiable {
    static let desktopUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 " +
        "(KHTML, like Gecko) Version/18.0 Safari/605.1.15 SwiftSurf/1.0"
    static let mobileUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 " +
        "(KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    let id = UUID()
    let isPrivate: Bool
    let webView: WKWebView
    /// The tab whose page opened this one as a pop-up; it is reselected when the pop-up closes.
    @ObservationIgnored var openerID: UUID?

    var url: URL?
    var title = ""
    var isLoading = false
    var estimatedProgress = 0.0
    var error: String?
    var canGoBack = false
    var canGoForward = false
    var favicon: NSImage?
    var isReaderActive = false
    var requestsMobileSite = false
    var dialog: JavaScriptDialog?

    /// A restored URL that is only loaded once the tab is first shown.
    @ObservationIgnored private(set) var pendingURL: URL?
    @ObservationIgnored private var delegate: BrowserTabDelegate?
    @ObservationIgnored private var observations: [NSKeyValueObservation] = []

    @ObservationIgnored var onFinishNavigation: ((BrowserTab) -> Void)?
    @ObservationIgnored var onOpenInNewTab: ((URLRequest, _ configuration: WKWebViewConfiguration?) -> WKWebView?)?
    @ObservationIgnored var onCloseRequest: ((BrowserTab) -> Void)?
    @ObservationIgnored var onDownload: ((WKDownload) -> Void)?

    init(isPrivate: Bool, configuration: WKWebViewConfiguration) {
        self.isPrivate = isPrivate
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = Self.desktopUserAgent

        let delegate = BrowserTabDelegate()
        delegate.tab = self
        self.delegate = delegate
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        observeWebView()
    }

    /// The URL to show in the address bar and to persist, including not-yet-loaded restored tabs.
    var displayURL: URL? { url ?? pendingURL }

    var host: String? { displayURL?.host }

    func load(_ address: String, searchEngine: SearchEngine) {
        guard let url = AddressResolver.url(for: address, searchEngine: searchEngine) else { return }
        load(url)
    }

    func load(_ url: URL) {
        pendingURL = nil
        error = nil
        webView.load(URLRequest(url: url))
    }

    func deferLoading(_ url: URL) {
        pendingURL = url
        title = url.host ?? url.absoluteString
    }

    func loadPendingURLIfNeeded() {
        if let pendingURL {
            load(pendingURL)
        }
    }

    func reload() {
        error = nil
        if let pendingURL {
            load(pendingURL)
        } else if webView.url == nil, let url {
            webView.load(URLRequest(url: url))
        } else {
            webView.reload()
        }
    }

    func setRequestsMobileSite(_ enabled: Bool) {
        requestsMobileSite = enabled
        webView.customUserAgent = enabled ? Self.mobileUserAgent : Self.desktopUserAgent
        webView.reload()
    }

    // MARK: Zoom

    static let zoomLevels: [Double] = [0.5, 0.67, 0.75, 0.8, 0.9, 1, 1.1, 1.25, 1.5, 1.75, 2, 2.5, 3]

    private(set) var zoom = 1.0

    func zoomIn() { setZoom(Self.zoomLevels.first { $0 > zoom + 0.001 } ?? zoom) }

    func zoomOut() { setZoom(Self.zoomLevels.last { $0 < zoom - 0.001 } ?? zoom) }

    func resetZoom() { setZoom(1) }

    private func setZoom(_ value: Double) {
        zoom = value
        webView.pageZoom = CGFloat(value)
        guard !isPrivate, let host = webView.url?.host else { return }
        var levels = UserDefaults.standard.dictionary(forKey: PreferenceKey.pageZoom) as? [String: Double] ?? [:]
        levels[host] = value == 1 ? nil : value
        UserDefaults.standard.set(levels, forKey: PreferenceKey.pageZoom)
    }

    private func applySavedZoom() {
        let levels = UserDefaults.standard.dictionary(forKey: PreferenceKey.pageZoom) as? [String: Double] ?? [:]
        let value = webView.url?.host.flatMap { levels[$0] } ?? 1
        zoom = value
        if abs(Double(webView.pageZoom) - value) > 0.001 {
            webView.pageZoom = CGFloat(value)
        }
    }

    // MARK: Page tools

    /// Highlights the next match of `text`; reports whether anything was found.
    func find(_ text: String, backwards: Bool = false, completion: @escaping (Bool) -> Void) {
        guard !text.isEmpty else {
            completion(true)
            return
        }
        let configuration = WKFindConfiguration()
        configuration.backwards = backwards
        configuration.caseSensitive = false
        configuration.wraps = true
        webView.find(text, configuration: configuration) { result in
            completion(result.matchFound)
        }
    }

    func toggleReader() {
        webView.evaluateJavaScript(PageScripts.toggleReader) { [weak self] result, _ in
            guard let shown = result as? Bool else {
                NSSound.beep()
                return
            }
            self?.isReaderActive = shown
        }
    }

    func togglePictureInPicture() {
        webView.evaluateJavaScript(PageScripts.togglePictureInPicture) { result, _ in
            if result as? Bool != true {
                NSSound.beep()
            }
        }
    }

    // MARK: Navigation events

    fileprivate func didStartNavigation() {
        error = nil
    }

    fileprivate func didCommitNavigation() {
        isReaderActive = false
        applySavedZoom()
    }

    fileprivate func didFinishNavigation() {
        onFinishNavigation?(self)
        loadFavicon()
    }

    fileprivate func didFail(_ error: Error) {
        let nsError = error as NSError
        // Cancelled loads and "frame load interrupted" (a navigation turned into a download) are not errors.
        guard nsError.code != NSURLErrorCancelled,
              !(nsError.domain == "WebKitErrorDomain" && nsError.code == 102) else { return }
        self.error = error.localizedDescription
    }

    fileprivate func present(_ dialog: JavaScriptDialog) {
        self.dialog?.complete(false, nil)
        self.dialog = dialog
    }

    func answerDialog(accepted: Bool, text: String? = nil) {
        let dialog = dialog
        self.dialog = nil
        dialog?.complete(accepted, text)
    }

    private func observeWebView() {
        func observe<Value>(_ keyPath: KeyPath<WKWebView, Value>, _ apply: @escaping (BrowserTab, WKWebView) -> Void) {
            observations.append(webView.observe(keyPath, options: [.initial, .new]) { [weak self] webView, _ in
                guard let self else { return }
                if Thread.isMainThread {
                    apply(self, webView)
                } else {
                    DispatchQueue.main.async { apply(self, webView) }
                }
            })
        }
        observe(\.url) { tab, webView in
            if webView.url != nil { tab.url = webView.url }
        }
        observe(\.title) { tab, webView in
            if let title = webView.title, !title.isEmpty {
                tab.title = title
            } else if let host = webView.url?.host {
                tab.title = host
            }
        }
        observe(\.isLoading) { tab, webView in tab.isLoading = webView.isLoading }
        observe(\.estimatedProgress) { tab, webView in tab.estimatedProgress = webView.estimatedProgress }
        observe(\.canGoBack) { tab, webView in tab.canGoBack = webView.canGoBack }
        observe(\.canGoForward) { tab, webView in tab.canGoForward = webView.canGoForward }
    }

    private func loadFavicon() {
        let pageHost = webView.url?.host
        webView.evaluateJavaScript(PageScripts.faviconURL) { [weak self] result, _ in
            guard let self, let string = result as? String, let iconURL = URL(string: string) else { return }
            FaviconCache.image(for: iconURL, ephemeral: self.isPrivate) { [weak self] image in
                guard let self, self.webView.url?.host == pageHost else { return }
                self.favicon = image
            }
        }
    }
}

/// Small in-memory cache of downloaded site icons.
enum FaviconCache {
    private static var images: [URL: NSImage] = [:]
    private static let ephemeralSession = URLSession(configuration: .ephemeral)

    static func image(for url: URL, ephemeral: Bool, completion: @escaping (NSImage?) -> Void) {
        if let image = images[url] {
            completion(image)
            return
        }
        let session = ephemeral ? ephemeralSession : URLSession.shared
        session.dataTask(with: url) { data, response, _ in
            let isOK = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            let image = isOK ? data.flatMap(NSImage.init(data:)) : nil
            DispatchQueue.main.async {
                if let image { images[url] = image }
                completion(image)
            }
        }.resume()
    }
}

private final class BrowserTabDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var tab: BrowserTab?

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
            return
        }
        // ⌘-click opens links in a new tab, like Safari.
        if navigationAction.navigationType == .linkActivated,
           navigationAction.modifierFlags.contains(.command),
           let tab, let open = tab.onOpenInNewTab {
            _ = open(navigationAction.request, nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let disposition = (navigationResponse.response as? HTTPURLResponse)?
            .value(forHTTPHeaderField: "Content-Disposition")?.lowercased() ?? ""
        if !navigationResponse.canShowMIMEType || (navigationResponse.isForMainFrame && disposition.hasPrefix("attachment")) {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        tab?.onDownload?(download)
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        tab?.onDownload?(download)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab?.didStartNavigation()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        tab?.didCommitNavigation()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        tab?.didFinishNavigation()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        tab?.didFail(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        tab?.didFail(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: WKUIDelegate

    /// `window.open` and `target="_blank"`: the new web view must use WebKit's configuration so the
    /// page keeps `window.opener`, which OAuth and payment pop-ups rely on.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        if let open = tab?.onOpenInNewTab {
            return open(navigationAction.request, configuration)
        }
        webView.load(navigationAction.request)
        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        guard let tab else { return }
        tab.onCloseRequest?(tab)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let tab else { return completionHandler() }
        tab.present(JavaScriptDialog(kind: .alert, message: message, host: frame.securityOrigin.host) { _, _ in
            completionHandler()
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let tab else { return completionHandler(false) }
        tab.present(JavaScriptDialog(kind: .confirm, message: message, host: frame.securityOrigin.host) { accepted, _ in
            completionHandler(accepted)
        })
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let tab else { return completionHandler(nil) }
        let kind = JavaScriptDialog.Kind.prompt(defaultText: defaultText ?? "")
        tab.present(JavaScriptDialog(kind: kind, message: prompt, host: frame.securityOrigin.host) { accepted, text in
            completionHandler(accepted ? (text ?? "") : nil)
        })
    }

    /// `<input type="file">`
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = parameters.allowsDirectories
        panel.canChooseFiles = true
        MenuBarController.keepPopoverOpen { done in
            panel.begin { response in
                completionHandler(response == .OK ? panel.urls : nil)
                done()
            }
        }
    }

    /// Camera and microphone: let WebKit ask the user, backed by the app's TCC permission.
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.prompt)
    }
}
