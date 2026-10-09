//
//  ContentView.swift
//  swiftsurf
//

import Combine
import Cocoa
import SwiftUI
import WebKit

struct Bookmark: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: String

    init(title: String, url: String) {
        id = UUID()
        self.title = title
        self.url = url
    }
}

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let visitedAt: Date
}

@MainActor
final class BrowserSession: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selectedTabID: UUID?
    @Published var bookmarks: [Bookmark] = []
    @Published var history: [HistoryEntry] = []
    @Published var privateMode = false
    @Published private(set) var navigationRevision = 0

    private let bookmarksKey = "bookmarks"
    private let historyKey = "history"

    init() {
        bookmarks = load([Bookmark].self, key: bookmarksKey) ?? []
        history = load([HistoryEntry].self, key: historyKey) ?? []
        addTab()
    }

    var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabID }
    }

    func addTab(url: String? = nil) {
        let tab = BrowserTab(isPrivate: privateMode)
        tab.onStateChange = { [weak self, weak tab] in
            guard let self, let tab, self.selectedTabID == tab.id else { return }
            self.navigationRevision += 1
        }
        tabs.append(tab)
        selectedTabID = tab.id
        navigationRevision += 1
        if let url {
            tab.load(url)
        }
    }

    func close(_ tab: BrowserTab) {
        guard tabs.count > 1 else { return }
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)
            if selectedTabID == tab.id {
                selectedTabID = tabs[min(index, tabs.count - 1)].id
            }
            navigationRevision += 1
        }
    }

    func record(_ tab: BrowserTab) {
        guard !tab.isPrivate, let url = tab.url?.absoluteString else { return }
        history.removeAll { $0.url == url }
        history.insert(HistoryEntry(id: UUID(), title: tab.title, url: url, visitedAt: Date()), at: 0)
        history = Array(history.prefix(50))
        save(history, key: historyKey)
    }

    func toggleBookmark(for tab: BrowserTab) {
        guard let url = tab.url?.absoluteString else { return }
        if let index = bookmarks.firstIndex(where: { $0.url == url }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.insert(Bookmark(title: tab.title.isEmpty ? url : tab.title, url: url), at: 0)
        }
        save(bookmarks, key: bookmarksKey)
    }

    func isBookmarked(_ tab: BrowserTab) -> Bool {
        guard let url = tab.url?.absoluteString else { return false }
        return bookmarks.contains { $0.url == url }
    }

    func clearBrowsingData() {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                  modifiedSince: .distantPast) {}
        history.removeAll()
        save(history, key: historyKey)
    }

    func setPrivateMode(_ enabled: Bool) {
        privateMode = enabled
        if enabled {
            addTab()
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    let isPrivate: Bool
    let webView: WKWebView
    private var navigationDelegate: BrowserNavigationDelegate!
    var onStateChange: (() -> Void)?
    @Published var url: URL?
    @Published var title = "New Tab"
    @Published var isLoading = false
    @Published var error: String?
    @Published var canGoBack = false
    @Published var canGoForward = false

    init(isPrivate: Bool) {
        self.isPrivate = isPrivate
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.applicationNameForUserAgent = "SwiftSurf/1.0"
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView = WKWebView(frame: .zero, configuration: configuration)
        let delegate = BrowserNavigationDelegate(tab: nil)
        navigationDelegate = delegate
        delegate.tab = self
        webView.navigationDelegate = delegate
        webView.uiDelegate = delegate
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) " +
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15 SwiftSurf/1.0"
    }

    func load(_ address: String) {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let destination: String
        if trimmed.contains("://") {
            destination = trimmed
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            destination = "https://" + trimmed
        } else {
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            destination = "https://www.google.com/search?q=" + query
        }
        guard let url = URL(string: destination) else { return }
        webView.load(URLRequest(url: url))
    }

    func reload() {
        error = nil
        webView.reload()
    }

    func updateNavigationState() {
        url = webView.url
        title = webView.title?.isEmpty == false ? webView.title! : (webView.url?.host ?? "New Tab")
        isLoading = webView.isLoading
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        onStateChange?()
    }
}

private final class BrowserNavigationDelegate: NSObject, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    weak var tab: BrowserTab?

    init(tab: BrowserTab?) {
        self.tab = tab
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        tab?.error = nil
        tab?.updateNavigationState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        update(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        update(webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        fail(error)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        webView.load(navigationAction.request)
        return nil
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if !navigationResponse.canShowMIMEType {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedFilename
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        completionHandler(panel.runModal() == .OK ? panel.url : nil)
    }

    func downloadDidFinish(_ download: WKDownload) {
        NSSound.beep()
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        NSLog("SwiftSurf download error: %@", error.localizedDescription)
    }

    private func update(_ webView: WKWebView) {
        tab?.updateNavigationState()
    }

    private func fail(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        tab?.error = error.localizedDescription
        tab?.updateNavigationState()
    }
}

struct ContentView: View {
    @StateObject private var session = BrowserSession()
    @AppStorage("homePage") private var homePage = "https://www.google.com/"
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    @State private var address = ""
    @State private var showingHistory = false
    @State private var showingSettings = false
    @State private var languageRevision = 0
    @FocusState private var addressIsFocused: Bool

    private var tab: BrowserTab? { session.selectedTab }
    private var strings: AppStrings {
        AppStrings(language: AppLanguage(rawValue: appLanguage) ?? .english)
    }

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            if showingSettings {
                SettingsTabView()
            } else {
                toolbar

                if let tab {
                    WebViewController(webView: tab.webView)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 10)
                        .overlay(alignment: .bottomTrailing) {
                            ResizeHandle()
                                .frame(width: 28, height: 28)
                                .padding(.trailing, 8)
                                .padding(.bottom, 6)
                        }
                        .overlay {
                            if let error = tab.error {
                                NavigationErrorView(message: error) {
                                    tab.webView.reload()
                                }
                            }
                        }
                }
            }
        }
        .frame(minWidth: ResizablePopover.minimumContentSize.width,
               idealWidth: 680,
               minHeight: ResizablePopover.minimumContentSize.height,
               idealHeight: 720)
        .background(.regularMaterial)
        .onAppear {
            if let tab, tab.url == nil {
                tab.load(homePage)
            }
            syncAddress()
        }
        .onReceive(session.$navigationRevision) { _ in syncAddress() }
        .sheet(isPresented: $showingHistory) {
            HistoryView(entries: session.history) { entry in
                tab?.load(entry.url)
                showingHistory = false
            }
        }
        .background {
            HStack(spacing: 0) {
                Button("") { tab?.webView.reload() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("") { if let tab { session.close(tab) } }
                    .keyboardShortcut("w", modifiers: .command)
            }
            .frame(width: 0, height: 0)
            .opacity(0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .swiftSurfShowHistory)) { _ in
            showingHistory = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .swiftSurfNewTab)) { _ in
            session.addTab()
        }
        .onReceive(NotificationCenter.default.publisher(for: .swiftSurfFocusAddress)) { _ in
            addressIsFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .swiftSurfLanguageChanged)) { _ in
            languageRevision += 1
        }
    }

    private var tabBar: some View {
        HStack(spacing: 5) {
            ForEach(session.tabs) { item in
                Button {
                    showingSettings = false
                    session.selectedTabID = item.id
                    syncAddress()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item.isPrivate ? "eye.slash" : "globe")
                        Text(item.title)
                            .lineLimit(1)
                        if session.tabs.count > 1 {
                            Button {
                                session.close(item)
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(session.selectedTabID == item.id ? Color.primary.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }

            Button {
                showingSettings = false
                session.addTab()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("t", modifiers: .command)

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .frame(width: 24, height: 24)
                    .background(showingSettings ? Color.primary.opacity(0.1) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()
            if session.privateMode {
                Label(strings["private"], systemImage: "eye.slash")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.purple)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            CircleIconButton(systemName: "chevron.left", isEnabled: tab?.canGoBack == true) {
                tab?.webView.goBack()
            }
            CircleIconButton(systemName: "chevron.right", isEnabled: tab?.canGoForward == true) {
                tab?.webView.goForward()
            }

            HStack(spacing: 8) {
                Image(systemName: tab?.url?.scheme == "https" ? "lock.fill" : "globe")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                TextField(strings["search"], text: $address) {
                    tab?.load(address)
                }
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($addressIsFocused)
                .onSubmit { tab?.load(address) }
                if tab?.isLoading == true {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            CircleIconButton(systemName: "arrow.clockwise") { tab?.reload() }
            Menu {
                Button(tab.map(session.isBookmarked) == true ? strings["removeBookmark"] : strings["addBookmark"]) {
                    if let tab { session.toggleBookmark(for: tab) }
                }
                Menu(strings["bookmarks"]) {
                    ForEach(session.bookmarks) { bookmark in
                        Button(bookmark.title) { tab?.load(bookmark.url) }
                    }
                }
                Menu(strings["recent"]) {
                    ForEach(session.history.prefix(10)) { entry in
                        Button(entry.title) { tab?.load(entry.url) }
                    }
                    Button(strings["showHistory"]) {
                        showingHistory = true
                    }
                }
                Divider()
                Toggle(strings["privateBrowsing"], isOn: Binding(get: { session.privateMode }, set: session.setPrivateMode))
                Button(strings["clearData"], role: .destructive) { session.clearBrowsingData() }
                Button(strings["downloads"]) {
                    NSWorkspace.shared.open(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0])
                }
                Divider()
                Button(strings["quit"]) {
                    NSApp.terminate(nil)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 28)
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }

    private func syncAddress() {
        address = tab?.url?.absoluteString ?? ""
    }
}

private struct NavigationErrorView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    let message: String
    let retry: () -> Void

    var body: some View {
        let strings = AppStrings(language: AppLanguage(rawValue: appLanguage) ?? .english)
        VStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark").font(.title2).foregroundStyle(.secondary)
            Text(strings["unable"]).font(.headline)
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).lineLimit(3)
            Button(strings["tryAgain"], action: retry).buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12, y: 4)
    }
}

private struct HistoryView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue
    let entries: [HistoryEntry]
    let select: (HistoryEntry) -> Void

    var body: some View {
        let strings = AppStrings(language: AppLanguage(rawValue: appLanguage) ?? .english)
        VStack(alignment: .leading, spacing: 12) {
            Text(strings["recentPages"]).font(.title2.weight(.semibold))
            if entries.isEmpty {
                Text(strings["noRecent"]).foregroundStyle(.secondary)
            } else {
                List(entries) { entry in
                    Button { select(entry) } label: {
                        VStack(alignment: .leading) {
                            Text(entry.title).font(.headline)
                            Text(entry.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }.buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(width: 460, height: 360)
    }
}

private struct CircleIconButton: View {
    let systemName: String
    var isEnabled = true
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName).font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(isEnabled ? 0.08 : 0.03))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? .primary : .tertiary)
        .disabled(!isEnabled)
    }
}

struct WebViewController: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WKWebView {
        webView.autoresizingMask = [.width, .height]
        webView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        webView.setContentHuggingPriority(.defaultLow, for: .vertical)
        webView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        webView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return webView
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
