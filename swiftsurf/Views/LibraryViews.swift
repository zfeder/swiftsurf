//
//  LibraryViews.swift
//  swiftsurf
//

import SwiftUI

struct HistoryView: View {
    let session: BrowserSession
    let strings: AppStrings
    let select: (HistoryEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var entries: [HistoryEntry] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !needle.isEmpty else { return session.history }
        return session.history.filter {
            $0.title.lowercased().contains(needle) || $0.url.lowercased().contains(needle)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(strings["recentPages"]).font(.title2.weight(.semibold))
                Spacer()
                TextField(strings["searchHistory"], text: $query)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
            }
            if entries.isEmpty {
                Text(strings["noRecent"]).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries) { entry in
                    Button { select(entry) } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.title).font(.headline).lineLimit(1)
                                Text(entry.url).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Text(entry.visitedAt, style: .relative)
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(strings["delete"], role: .destructive) { session.removeHistoryEntry(entry) }
                    }
                }
            }
            HStack {
                Button(strings["clearHistory"], role: .destructive) { session.clearHistory() }
                    .disabled(session.history.isEmpty)
                Spacer()
                Button(strings["done"]) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 520, height: 420)
    }
}

struct DownloadsView: View {
    let downloads: DownloadManager
    let strings: AppStrings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(strings["command.showDownloads"]).font(.title2.weight(.semibold))
            if downloads.items.isEmpty {
                Text(strings["noDownloads"]).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(downloads.items) { item in
                    DownloadRow(item: item, downloads: downloads, strings: strings)
                }
            }
            HStack {
                Button(strings["openDownloadsFolder"]) {
                    NSWorkspace.shared.open(DownloadManager.downloadsDirectory)
                }
                Button(strings["clearList"]) { downloads.clearInactive() }
                    .disabled(downloads.items.allSatisfy { $0.state == .downloading })
                Spacer()
                Button(strings["done"]) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 480, height: 360)
    }
}

private struct DownloadRow: View {
    let item: DownloadItem
    let downloads: DownloadManager
    let strings: AppStrings

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "doc").font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename).lineLimit(1)
                switch item.state {
                case .downloading:
                    ProgressView(value: item.fractionCompleted).controlSize(.small)
                case .finished:
                    Text(strings["downloadFinished"]).font(.caption).foregroundStyle(.secondary)
                case .cancelled:
                    Text(strings["downloadCancelled"]).font(.caption).foregroundStyle(.secondary)
                case .failed(let message):
                    Text(message).font(.caption).foregroundStyle(.red).lineLimit(2)
                }
            }
            Spacer()
            if item.state == .downloading {
                Button { downloads.cancel(item) } label: { Image(systemName: "xmark.circle") }
                    .buttonStyle(.plain)
                    .help(strings["cancel"])
            } else if item.state == .finished {
                Button { downloads.reveal(item) } label: { Image(systemName: "magnifyingglass.circle") }
                    .buttonStyle(.plain)
                    .help(strings["showInFinder"])
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if item.state == .finished { downloads.open(item) }
        }
    }
}
