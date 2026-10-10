//
//  Models.swift
//  swiftsurf
//

import Foundation

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

struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let url: String
    let visitedAt: Date

    init(id: UUID = UUID(), title: String, url: String, visitedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.visitedAt = visitedAt
    }

    static let limit = 1_000

    /// Moves `entry` to the top of `history`, dropping older visits of the same URL.
    static func recording(_ entry: HistoryEntry, in history: [HistoryEntry], limit: Int = limit) -> [HistoryEntry] {
        Array(([entry] + history.filter { $0.url != entry.url }).prefix(limit))
    }
}

/// A row shown under the address bar while typing.
struct AddressSuggestion: Identifiable, Equatable {
    enum Kind { case bookmark, history }

    let kind: Kind
    let title: String
    let url: String
    var id: String { url }

    /// Bookmarks first, then the most recent history entries whose title or URL contain `query`.
    static func matching(_ query: String, bookmarks: [Bookmark], history: [HistoryEntry],
                         limit: Int = 6) -> [AddressSuggestion] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard needle.count >= 2 else { return [] }
        func matches(_ title: String, _ url: String) -> Bool {
            title.lowercased().contains(needle) || url.lowercased().contains(needle)
        }
        var seen = Set<String>()
        var results: [AddressSuggestion] = []
        for bookmark in bookmarks where matches(bookmark.title, bookmark.url) && seen.insert(bookmark.url).inserted {
            results.append(AddressSuggestion(kind: .bookmark, title: bookmark.title, url: bookmark.url))
        }
        for entry in history where matches(entry.title, entry.url) && seen.insert(entry.url).inserted {
            results.append(AddressSuggestion(kind: .history, title: entry.title, url: entry.url))
        }
        return Array(results.prefix(limit))
    }
}
