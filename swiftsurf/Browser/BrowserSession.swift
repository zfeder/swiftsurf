//
//  BrowserSession.swift
//  swiftsurf
//

import Foundation
import Observation
import WebKit

/// Tabs, bookmarks, history and downloads for the single SwiftSurf window.
@Observable
final class BrowserSession {
    private(set) var tabs: [BrowserTab] = []
    var selectedTabID: UUID? {
        didSet {
            selectedTab?.loadPendingURLIfNeeded()
            saveSession()
        }
    }
    private(set) var bookmarks: [Bookmark]
    private(set) var history: [HistoryEntry]
    private(set) var privateMode = false
    let downloads = DownloadManager()

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let bookmarkStore = PersistentStore<[Bookmark]>(name: "bookmarks", legacyDefaultsKey: "bookmarks")
    @ObservationIgnored private let historyStore = PersistentStore<[HistoryEntry]>(name: "history", legacyDefaultsKey: "history")
    /// Shared by every private tab so they see each other's logins, and discarded when private mode ends.
    @ObservationIgnored private var privateDataStore: WKWebsiteDataStore?
    @ObservationIgnored private var recentlyClosedURLs: [URL] = []
    @ObservationIgnored private var blocksTrackers: Bool
    @ObservationIgnored private var defaultsObserver: NSObjectProtocol?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        bookmarks = bookmarkStore.load() ?? []
        history = historyStore.load() ?? []
        blocksTrackers = defaults.bool(forKey: PreferenceKey.blockTrackers, default: true)

        if !restoreSession() {
            addTab(url: URL(string: defaults.homePage))
        }
        if blocksTrackers {
            applyContentBlocker()
        }
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: defaults, queue: .main
        ) { [weak self] _ in
            self?.preferencesChanged()
        }
    }

    deinit {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    var selectedTab: BrowserTab? {
        tabs.first { $0.id == selectedTabID }
    }

    var searchEngine: SearchEngine { defaults.searchEngine }

    // MARK: Tabs

    /// Opens a tab after the selected one. A `configuration` from WebKit (pop-ups) must be used as is.
    @discardableResult
    func addTab(url: URL? = nil, configuration: WKWebViewConfiguration? = nil,
                isPrivate: Bool? = nil, select: Bool = true) -> BrowserTab {
        let isPrivate = isPrivate ?? privateMode
        let tab = BrowserTab(isPrivate: isPrivate, configuration: configuration ?? makeConfiguration(isPrivate: isPrivate))
        connect(tab)
        let index = selectedTab.flatMap { selected in tabs.firstIndex { $0.id == selected.id } }.map { $0 + 1 } ?? tabs.count
        tabs.insert(tab, at: index)
        if let url {
            tab.load(url)
        }
        if select {
            selectedTabID = tab.id
        }
        return tab
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        if tabs.count == 1 {
            // Keep one tab around; closing the last one resets it to a blank page.
            if let url = tab.displayURL, !tab.isPrivate { recentlyClosedURLs.append(url) }
            tabs.removeAll()
            tear(down: tab)
            addTab(isPrivate: false)
            return
        }
        if let url = tab.displayURL, !tab.isPrivate {
            recentlyClosedURLs.append(url)
            recentlyClosedURLs = Array(recentlyClosedURLs.suffix(20))
        }
        tabs.remove(at: index)
        tear(down: tab)
        if selectedTabID == tab.id {
            let opener = tabs.first { $0.id == tab.openerID }
            selectedTabID = opener?.id ?? tabs[min(index, tabs.count - 1)].id
        } else {
            saveSession()
        }
    }

    var canReopenClosedTab: Bool { !recentlyClosedURLs.isEmpty }

    func reopenClosedTab() {
        guard let url = recentlyClosedURLs.popLast() else { return }
        addTab(url: url, isPrivate: false)
    }

    func selectTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        selectedTabID = tabs[index].id
    }

    /// Selects the tab `offset` positions away, wrapping around.
    func selectTab(offset: Int) {
        guard let current = tabs.firstIndex(where: { $0.id == selectedTabID }), !tabs.isEmpty else { return }
        selectTab(at: (current + offset + tabs.count) % tabs.count)
    }

    func moveTab(_ id: UUID, before targetID: UUID) {
        guard id != targetID,
              let from = tabs.firstIndex(where: { $0.id == id }),
              let to = tabs.firstIndex(where: { $0.id == targetID }) else { return }
        tabs.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        saveSession()
    }

    private func connect(_ tab: BrowserTab) {
        tab.onFinishNavigation = { [weak self] tab in
            self?.record(tab)
            self?.saveSession()
        }
        tab.onOpenInNewTab = { [weak self, weak tab] request, configuration in
            guard let self else { return nil }
            let isPopup = configuration != nil
            let newTab = self.addTab(configuration: configuration, isPrivate: tab?.isPrivate, select: isPopup)
            if isPopup {
                newTab.openerID = tab?.id
            } else {
                newTab.webView.load(request)
            }
            return isPopup ? newTab.webView : nil
        }
        tab.onCloseRequest = { [weak self] tab in
            self?.close(tab)
        }
        tab.onDownload = { [weak self] download in
            self?.downloads.track(download)
        }
    }

    private func tear(down tab: BrowserTab) {
        tab.answerDialog(accepted: false)
        tab.webView.stopLoading()
    }

    private func makeConfiguration(isPrivate: Bool) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        if isPrivate {
            let store = privateDataStore ?? .nonPersistent()
            privateDataStore = store
            configuration.websiteDataStore = store
        } else {
            configuration.websiteDataStore = .default()
        }
        configuration.applicationNameForUserAgent = "SwiftSurf/1.0"
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        // Pop-ups still open from clicks; this only blocks unsolicited `window.open` calls.
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.preferences.isElementFullscreenEnabled = true
        if blocksTrackers, let ruleList = ContentBlocker.shared.ruleList {
            configuration.userContentController.add(ruleList)
        }
        return configuration
    }

    // MARK: Private browsing

    func setPrivateMode(_ enabled: Bool) {
        guard enabled != privateMode else { return }
        privateMode = enabled
        if enabled {
            addTab(isPrivate: true)
            return
        }
        let privateTabs = tabs.filter(\.isPrivate)
        tabs.removeAll(where: \.isPrivate)
        privateTabs.forEach(tear(down:))
        privateDataStore = nil
        if tabs.isEmpty {
            addTab(url: URL(string: defaults.homePage), isPrivate: false)
        } else if selectedTab == nil {
            selectedTabID = tabs.last?.id
        }
    }

    // MARK: History and bookmarks

    func record(_ tab: BrowserTab) {
        guard !tab.isPrivate, let url = tab.url, ["http", "https"].contains(url.scheme) else { return }
        let entry = HistoryEntry(title: tab.title.isEmpty ? (url.host ?? url.absoluteString) : tab.title,
                                 url: url.absoluteString)
        history = HistoryEntry.recording(entry, in: history)
        historyStore.save(history)
    }

    func removeHistoryEntry(_ entry: HistoryEntry) {
        history.removeAll { $0.id == entry.id }
        historyStore.save(history)
    }

    func clearHistory() {
        history.removeAll()
        historyStore.save(history)
    }

    func isBookmarked(_ url: URL?) -> Bool {
        guard let url = url?.absoluteString else { return false }
        return bookmarks.contains { $0.url == url }
    }

    func toggleBookmark(for tab: BrowserTab) {
        guard let url = tab.displayURL?.absoluteString else { return }
        if let index = bookmarks.firstIndex(where: { $0.url == url }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.insert(Bookmark(title: tab.title.isEmpty ? url : tab.title, url: url), at: 0)
        }
        bookmarkStore.save(bookmarks)
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        bookmarkStore.save(bookmarks)
    }

    func suggestions(for text: String) -> [AddressSuggestion] {
        AddressSuggestion.matching(text, bookmarks: bookmarks, history: history)
    }

    func clearBrowsingData() {
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                                                modifiedSince: .distantPast) {}
        clearHistory()
        recentlyClosedURLs.removeAll()
        defaults.removeObject(forKey: PreferenceKey.pageZoom)
    }

    // MARK: Session restore

    private func restoreSession() -> Bool {
        guard defaults.bool(forKey: PreferenceKey.restoreSession, default: true),
              let urls = defaults.stringArray(forKey: PreferenceKey.sessionTabs)?.compactMap(URL.init(string:)),
              !urls.isEmpty else { return false }
        for url in urls {
            addTab(select: false).deferLoading(url)
        }
        let index = defaults.integer(forKey: PreferenceKey.sessionSelectedIndex)
        selectTab(at: tabs.indices.contains(index) ? index : 0)
        return true
    }

    private func saveSession() {
        guard defaults.bool(forKey: PreferenceKey.restoreSession, default: true) else {
            defaults.removeObject(forKey: PreferenceKey.sessionTabs)
            return
        }
        let savedTabs = tabs.filter { tab in
            !tab.isPrivate && ["http", "https"].contains(tab.displayURL?.scheme)
        }
        defaults.set(savedTabs.compactMap { $0.displayURL?.absoluteString }, forKey: PreferenceKey.sessionTabs)
        defaults.set(savedTabs.firstIndex { $0.id == selectedTabID } ?? 0, forKey: PreferenceKey.sessionSelectedIndex)
    }

    // MARK: Content blocking

    private func preferencesChanged() {
        let enabled = defaults.bool(forKey: PreferenceKey.blockTrackers, default: true)
        guard enabled != blocksTrackers else { return }
        blocksTrackers = enabled
        if enabled {
            applyContentBlocker()
        } else {
            tabs.forEach { $0.webView.configuration.userContentController.removeAllContentRuleLists() }
        }
    }

    private func applyContentBlocker() {
        ContentBlocker.shared.load { [weak self] ruleList in
            guard let self, self.blocksTrackers, let ruleList else { return }
            for tab in self.tabs {
                tab.webView.configuration.userContentController.remove(ruleList)
                tab.webView.configuration.userContentController.add(ruleList)
            }
        }
    }
}
