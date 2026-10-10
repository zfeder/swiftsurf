//
//  ToolbarView.swift
//  swiftsurf
//

import SwiftUI

struct ToolbarView: View {
    let session: BrowserSession
    let tab: BrowserTab
    let strings: AppStrings
    /// Incremented by the parent to move keyboard focus into the address field.
    let focusRequest: Int
    let perform: (BrowserCommand) -> Void

    @AppStorage(PreferenceKey.keepPopoverOpen) private var keepPopoverOpen = false
    @FocusState private var addressIsFocused: Bool
    /// What the user typed; `nil` while the field just mirrors the current page.
    @State private var editedAddress: String?
    @State private var highlightedSuggestion: Int?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                CircleIconButton(systemName: "chevron.left", isEnabled: tab.canGoBack,
                                 help: strings["command.goBack"]) { tab.webView.goBack() }
                CircleIconButton(systemName: "chevron.right", isEnabled: tab.canGoForward,
                                 help: strings["command.goForward"]) { tab.webView.goForward() }
                addressField
                if tab.isLoading {
                    CircleIconButton(systemName: "xmark", help: strings["stop"]) { tab.webView.stopLoading() }
                } else {
                    CircleIconButton(systemName: "arrow.clockwise", help: strings["command.reload"]) { tab.reload() }
                }
                downloadsButton
                CircleIconButton(systemName: keepPopoverOpen ? "pin.fill" : "pin",
                                 help: strings["keepOpen"]) { keepPopoverOpen.toggle() }
                ToolbarMenu(session: session, tab: tab, strings: strings, perform: perform)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            if !suggestions.isEmpty {
                suggestionList
            }
        }
        .background(.regularMaterial)
        .onChange(of: focusRequest) { _, _ in
            addressIsFocused = true
        }
        .onChange(of: tab.id) { _, _ in
            editedAddress = nil
        }
    }

    private var addressText: Binding<String> {
        Binding(
            get: { editedAddress ?? tab.displayURL?.absoluteString ?? "" },
            set: { newValue in
                editedAddress = newValue
                highlightedSuggestion = nil
            }
        )
    }

    private var suggestions: [AddressSuggestion] {
        guard addressIsFocused, let editedAddress else { return [] }
        return session.suggestions(for: editedAddress)
    }

    private var addressField: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.displayURL?.scheme == "https" ? "lock.fill" : "globe")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            TextField(strings["search"], text: addressText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($addressIsFocused)
                .onSubmit(submit)
                .onExitCommand {
                    editedAddress = nil
                    addressIsFocused = false
                }
                .onKeyPress(.downArrow) { moveHighlight(by: 1) }
                .onKeyPress(.upArrow) { moveHighlight(by: -1) }
            if tab.displayURL != nil {
                Button {
                    session.toggleBookmark(for: tab)
                } label: {
                    Image(systemName: session.isBookmarked(tab.displayURL) ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(session.isBookmarked(tab.displayURL) ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(session.isBookmarked(tab.displayURL) ? strings["removeBookmark"] : strings["addBookmark"])
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.07))
        .overlay(alignment: .bottom) {
            if tab.isLoading {
                LoadingProgressLine(progress: tab.estimatedProgress)
                    .padding(.horizontal, 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var downloadsButton: some View {
        if !session.downloads.items.isEmpty {
            let active = session.downloads.activeCount
            CircleIconButton(systemName: active > 0 ? "arrow.down.circle.fill" : "arrow.down.circle",
                             help: strings["command.showDownloads"]) { perform(.showDownloads) }
                .overlay(alignment: .topTrailing) {
                    if active > 0 {
                        Text("\(active)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Circle().fill(Color.accentColor))
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }

    private var suggestionList: some View {
        VStack(spacing: 2) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button {
                    open(suggestion.url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: suggestion.kind == .bookmark ? "star" : "clock")
                            .foregroundStyle(.secondary)
                            .frame(width: 16)
                        Text(suggestion.title).lineLimit(1)
                        Text(suggestion.url).lineLimit(1).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(highlightedSuggestion == index ? Color.accentColor.opacity(0.18) : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 54)
        .padding(.bottom, 8)
    }

    private func moveHighlight(by offset: Int) -> KeyPress.Result {
        let count = suggestions.count
        guard count > 0 else { return .ignored }
        let current = highlightedSuggestion ?? (offset > 0 ? -1 : count)
        highlightedSuggestion = min(max(current + offset, 0), count - 1)
        return .handled
    }

    private func submit() {
        if let index = highlightedSuggestion, suggestions.indices.contains(index) {
            open(suggestions[index].url)
            return
        }
        guard let text = editedAddress else { return }
        tab.load(text, searchEngine: session.searchEngine)
        finishEditing()
    }

    private func open(_ address: String) {
        if let url = URL(string: address) {
            tab.load(url)
        }
        finishEditing()
    }

    private func finishEditing() {
        editedAddress = nil
        highlightedSuggestion = nil
        addressIsFocused = false
    }
}

private struct ToolbarMenu: View {
    let session: BrowserSession
    let tab: BrowserTab
    let strings: AppStrings
    let perform: (BrowserCommand) -> Void

    var body: some View {
        Menu {
            Button(session.isBookmarked(tab.displayURL) ? strings["removeBookmark"] : strings["addBookmark"]) {
                perform(.toggleBookmark)
            }
            Menu(strings["bookmarks"]) {
                ForEach(session.bookmarks) { bookmark in
                    Button(bookmark.title) { open(bookmark.url) }
                }
            }
            Menu(strings["recent"]) {
                ForEach(session.history.prefix(10)) { entry in
                    Button(entry.title) { open(entry.url) }
                }
                Divider()
                Button(strings["command.showHistory"]) { perform(.showHistory) }
            }
            Button(strings["command.showDownloads"]) { perform(.showDownloads) }
            Button(strings["command.reopenClosedTab"]) { perform(.reopenClosedTab) }
                .disabled(!session.canReopenClosedTab)

            Divider()
            Button(strings["command.find"]) { perform(.find) }
            Menu(String(format: strings["zoomLevel"], Int((tab.zoom * 100).rounded()))) {
                Button(strings["command.zoomIn"]) { perform(.zoomIn) }
                Button(strings["command.zoomOut"]) { perform(.zoomOut) }
                Button(strings["command.actualSize"]) { perform(.actualSize) }
            }
            Button(tab.isReaderActive ? strings["exitReader"] : strings["command.toggleReader"]) {
                perform(.toggleReader)
            }
            Button(strings["pictureInPicture"]) { tab.togglePictureInPicture() }
            Toggle(strings["requestMobileSite"], isOn: Binding(get: { tab.requestsMobileSite },
                                                               set: tab.setRequestsMobileSite))

            Divider()
            Toggle(strings["privateBrowsing"], isOn: Binding(get: { session.privateMode },
                                                             set: session.setPrivateMode))
            Button(strings["clearData"], role: .destructive) { session.clearBrowsingData() }

            Divider()
            Button(strings["quit"]) {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 28)
    }

    private func open(_ address: String) {
        if let url = URL(string: address) {
            tab.load(url)
        }
    }
}
