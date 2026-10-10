//
//  ContentView.swift
//  swiftsurf
//

import SwiftUI

struct ContentView: View {
    @State private var session = BrowserSession()
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.systemDefault.rawValue
    @AppStorage(PreferenceKey.showFavoritesBar) private var showFavoritesBar = true
    @State private var showingSettings = false
    @State private var showingHistory = false
    @State private var showingDownloads = false
    @State private var addressFocusRequest = 0
    @State private var isFinding = false
    @State private var findText = ""
    @State private var findFoundMatch = true
    @State private var findFocusRequest = 0

    private var strings: AppStrings { AppStrings(rawValue: appLanguage) }

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(session: session, strings: strings, showingSettings: $showingSettings)
            if showingSettings {
                SettingsTabView()
            } else if let tab = session.selectedTab {
                ToolbarView(session: session, tab: tab, strings: strings,
                            focusRequest: addressFocusRequest, perform: perform)
                if showFavoritesBar && !session.bookmarks.isEmpty {
                    FavoritesBar(session: session, strings: strings) { url, newTab in
                        if newTab { session.addTab(url: url) } else { tab.load(url) }
                    }
                }
                if isFinding {
                    FindBar(text: $findText, foundMatch: findFoundMatch, strings: strings,
                            focusRequest: findFocusRequest, find: find, close: closeFindBar)
                }
                webArea(for: tab)
            }
        }
        .frame(minWidth: ResizablePopover.minimumContentSize.width,
               idealWidth: 680,
               minHeight: ResizablePopover.minimumContentSize.height,
               idealHeight: 720)
        .background(.regularMaterial)
        .background { keyboardShortcuts }
        .sheet(isPresented: $showingHistory) {
            HistoryView(session: session, strings: strings) { entry in
                if let url = URL(string: entry.url) { session.selectedTab?.load(url) }
                showingHistory = false
            }
        }
        .sheet(isPresented: $showingDownloads) {
            DownloadsView(downloads: session.downloads, strings: strings)
        }
        .onReceive(NotificationCenter.default.publisher(for: .swiftSurfCommand)) { notification in
            if let command = notification.object as? BrowserCommand {
                perform(command)
            }
        }
        .onChange(of: session.selectedTabID) { _, _ in
            closeFindBar()
        }
    }

    private func webArea(for tab: BrowserTab) -> some View {
        ZStack {
            if tab.displayURL == nil && !tab.isLoading {
                StartPage(session: session, strings: strings) { tab.load($0) }
            } else {
                WebViewContainer(webView: tab.webView)
            }
            if let error = tab.error {
                NavigationErrorView(strings: strings, message: error) { tab.reload() }
            }
            if let dialog = tab.dialog {
                Color.black.opacity(0.15)
                JavaScriptDialogView(dialog: dialog, strings: strings) { accepted, text in
                    tab.answerDialog(accepted: accepted, text: text)
                }
                .id(dialog.id)
            }
        }
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
    }

    /// Invisible buttons so shortcuts work inside the popover even when the app menu is hidden.
    private var keyboardShortcuts: some View {
        ZStack {
            ForEach(BrowserCommand.allCases, id: \.self) { command in
                Button("") { perform(command) }
                    .keyboardShortcut(command.shortcut)
            }
            Button("") { perform(.zoomIn) }
                .keyboardShortcut("+", modifiers: .command)
            ForEach(1...9, id: \.self) { number in
                Button("") {
                    // ⌘9 always selects the last tab, like Safari.
                    showingSettings = false
                    session.selectTab(at: number == 9 ? session.tabs.count - 1 : number - 1)
                }
                .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
            }
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func perform(_ command: BrowserCommand) {
        guard let tab = session.selectedTab else { return }
        switch command {
        case .newTab:
            showingSettings = false
            session.addTab()
            addressFocusRequest += 1
        case .reopenClosedTab:
            showingSettings = false
            session.reopenClosedTab()
        case .closeTab:
            if showingSettings {
                showingSettings = false
            } else {
                session.close(tab)
            }
        case .focusAddress:
            showingSettings = false
            addressFocusRequest += 1
        case .find:
            showingSettings = false
            isFinding = true
            findFocusRequest += 1
        case .findNext, .findPrevious:
            if isFinding {
                find(backwards: command == .findPrevious)
            } else {
                perform(.find)
            }
        case .reload: tab.reload()
        case .goBack: tab.webView.goBack()
        case .goForward: tab.webView.goForward()
        case .nextTab: session.selectTab(offset: 1)
        case .previousTab: session.selectTab(offset: -1)
        case .zoomIn: tab.zoomIn()
        case .zoomOut: tab.zoomOut()
        case .actualSize: tab.resetZoom()
        case .toggleReader: tab.toggleReader()
        case .toggleBookmark: session.toggleBookmark(for: tab)
        case .showHistory: showingHistory = true
        case .showDownloads: showingDownloads = true
        }
    }

    private func find(backwards: Bool) {
        session.selectedTab?.find(findText, backwards: backwards) { found in
            findFoundMatch = found
        }
    }

    private func closeFindBar() {
        isFinding = false
        findFoundMatch = true
    }
}
