//
//  PageAccessoryViews.swift
//  swiftsurf
//

import SwiftUI

/// ⌘F bar searching the current page.
struct FindBar: View {
    @Binding var text: String
    let foundMatch: Bool
    let strings: AppStrings
    let focusRequest: Int
    let find: (_ backwards: Bool) -> Void
    let close: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(strings["findPlaceholder"], text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { find(false) }
                .onExitCommand(perform: close)
                .frame(maxWidth: 260)
            if !foundMatch && !text.isEmpty {
                Text(strings["notFound"]).font(.caption).foregroundStyle(.red)
            }
            Spacer()
            Button { find(true) } label: { Image(systemName: "chevron.up") }
                .help(strings["command.findPrevious"])
            Button { find(false) } label: { Image(systemName: "chevron.down") }
                .help(strings["command.findNext"])
            Button(strings["done"], action: close)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .onAppear { isFocused = true }
        .onChange(of: focusRequest) { _, _ in isFocused = true }
        .onChange(of: text) { _, _ in find(false) }
    }
}

/// Bookmarks shown as one-click chips under the toolbar.
struct FavoritesBar: View {
    let session: BrowserSession
    let strings: AppStrings
    let open: (_ url: URL, _ newTab: Bool) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(session.bookmarks) { bookmark in
                    Button {
                        if let url = URL(string: bookmark.url) { open(url, false) }
                    } label: {
                        Label(bookmark.title, systemImage: "star")
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                            .frame(maxWidth: 150)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.06), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .help(bookmark.url)
                    .contextMenu {
                        Button(strings["openInNewTab"]) {
                            if let url = URL(string: bookmark.url) { open(url, true) }
                        }
                        Button(strings["removeBookmark"], role: .destructive) {
                            session.removeBookmark(bookmark)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 8)
    }
}

/// Shown in tabs that have nothing loaded yet.
struct StartPage: View {
    let session: BrowserSession
    let strings: AppStrings
    let open: (URL) -> Void

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !session.bookmarks.isEmpty {
                    section(strings["bookmarks"]) {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                            ForEach(session.bookmarks.prefix(12)) { bookmark in
                                tile(title: bookmark.title, url: bookmark.url)
                            }
                        }
                    }
                }
                if !session.history.isEmpty {
                    section(strings["recentPages"]) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(session.history.prefix(8)) { entry in
                                Button {
                                    if let url = URL(string: entry.url) { open(url) }
                                } label: {
                                    HStack {
                                        Image(systemName: "clock").foregroundStyle(.secondary)
                                        Text(entry.title).lineLimit(1)
                                        Text(entry.url).lineLimit(1).foregroundStyle(.secondary)
                                    }
                                    .font(.callout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                if session.bookmarks.isEmpty && session.history.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "globe").font(.system(size: 36)).foregroundStyle(.secondary)
                        Text(strings["startHint"]).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .padding(24)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
    }

    private func tile(title: String, url: String) -> some View {
        Button {
            if let url = URL(string: url) { open(url) }
        } label: {
            VStack(spacing: 6) {
                Text(String((URL(string: url)?.host ?? title).replacingOccurrences(of: "www.", with: "").prefix(1)).uppercased())
                    .font(.title2.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                Text(title).font(.caption).lineLimit(2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(url)
    }
}
