//
//  swiftsurfTests.swift
//  swiftsurfTests
//
//  Created by Federico Filì on 12/07/24.
//

import WebKit
import XCTest
@testable import swiftsurf

final class HistoryTests: XCTestCase {
    func testRecordingMovesRevisitedPageToTop() {
        let first = HistoryEntry(title: "A", url: "https://a.example")
        let second = HistoryEntry(title: "B", url: "https://b.example")
        var history = HistoryEntry.recording(first, in: [])
        history = HistoryEntry.recording(second, in: history)
        history = HistoryEntry.recording(HistoryEntry(title: "A again", url: "https://a.example"), in: history)

        XCTAssertEqual(history.map(\.url), ["https://a.example", "https://b.example"])
        XCTAssertEqual(history.first?.title, "A again")
    }

    func testRecordingRespectsLimit() {
        var history: [HistoryEntry] = []
        for index in 0..<10 {
            history = HistoryEntry.recording(HistoryEntry(title: "\(index)", url: "https://\(index).example"),
                                             in: history, limit: 3)
        }
        XCTAssertEqual(history.map(\.title), ["9", "8", "7"])
    }

    func testSuggestionsPreferBookmarksAndSkipDuplicates() {
        let bookmarks = [Bookmark(title: "Swift Forums", url: "https://forums.swift.org")]
        let history = [
            HistoryEntry(title: "Swift Forums", url: "https://forums.swift.org"),
            HistoryEntry(title: "Swift.org", url: "https://swift.org"),
            HistoryEntry(title: "Apple", url: "https://apple.com")
        ]
        let suggestions = AddressSuggestion.matching("SWIFT", bookmarks: bookmarks, history: history)

        XCTAssertEqual(suggestions.map(\.url), ["https://forums.swift.org", "https://swift.org"])
        XCTAssertEqual(suggestions.first?.kind, .bookmark)
        XCTAssertTrue(AddressSuggestion.matching("s", bookmarks: bookmarks, history: history).isEmpty)
    }
}

final class DownloadManagerTests: XCTestCase {
    func testUniqueDestinationAddsCounterBeforeExtension() {
        let directory = URL(fileURLWithPath: "/tmp/downloads")
        let taken: Set<String> = ["/tmp/downloads/report.pdf", "/tmp/downloads/report 2.pdf"]
        let url = DownloadManager.uniqueDestination(for: "report.pdf", in: directory) { taken.contains($0) }
        XCTAssertEqual(url.lastPathComponent, "report 3.pdf")
    }

    func testUniqueDestinationHandlesMissingExtensionAndSlashes() {
        let directory = URL(fileURLWithPath: "/tmp/downloads")
        XCTAssertEqual(DownloadManager.uniqueDestination(for: "a/b", in: directory) { _ in false }.lastPathComponent, "a-b")
        let taken: Set<String> = ["/tmp/downloads/README"]
        XCTAssertEqual(DownloadManager.uniqueDestination(for: "README", in: directory) { taken.contains($0) }
            .lastPathComponent, "README 2")
    }
}

final class ContentBlockerTests: XCTestCase {
    func testRulesAreValidJSONWithOneBlockRulePerDomain() throws {
        let data = Data(ContentBlocker.encodedRules.utf8)
        let rules = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        XCTAssertEqual(rules.count, ContentBlocker.blockedDomains.count)
        XCTAssertEqual(Set(ContentBlocker.blockedDomains).count, ContentBlocker.blockedDomains.count)

        for rule in rules {
            let action = try XCTUnwrap(rule["action"] as? [String: Any])
            XCTAssertEqual(action["type"] as? String, "block")
            let trigger = try XCTUnwrap(rule["trigger"] as? [String: Any])
            let filter = try XCTUnwrap(trigger["url-filter"] as? String)
            XCTAssertNoThrow(try NSRegularExpression(pattern: filter))
        }
    }

    func testWebKitCompilesTheRules() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try XCTUnwrap(WKContentRuleListStore(url: directory))
        let compiled = expectation(description: "compiled")
        store.compileContentRuleList(forIdentifier: "test", encodedContentRuleList: ContentBlocker.encodedRules) { list, error in
            XCTAssertNil(error)
            XCTAssertNotNil(list)
            compiled.fulfill()
        }
        wait(for: [compiled], timeout: 10)
    }

    func testRuleMatchesSubdomainsButNotLookalikes() throws {
        let rules = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(ContentBlocker.encodedRules.utf8)) as? [[String: Any]])
        let trigger = try XCTUnwrap(rules.first?["trigger"] as? [String: Any])
        let regex = try NSRegularExpression(pattern: try XCTUnwrap(trigger["url-filter"] as? String))
        func matches(_ url: String) -> Bool {
            regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)) != nil
        }
        XCTAssertTrue(matches("https://doubleclick.net/ad.js"))
        XCTAssertTrue(matches("https://stats.g.doubleclick.net/collect"))
        XCTAssertFalse(matches("https://notdoubleclick.net/"))
        XCTAssertFalse(matches("https://example.com/doubleclick.net/"))
    }
}

final class LocalizationTests: XCTestCase {
    func testEveryLanguageTranslatesEveryEnglishKey() throws {
        let english = try XCTUnwrap(AppStrings.tables[.english])
        for language in AppLanguage.allCases {
            let table = try XCTUnwrap(AppStrings.tables[language], language.rawValue)
            XCTAssertEqual(Set(table.keys), Set(english.keys), "Key mismatch in \(language.rawValue)")
        }
    }

    func testEveryCommandHasATitle() throws {
        let english = try XCTUnwrap(AppStrings.tables[.english])
        for command in BrowserCommand.allCases {
            XCTAssertNotNil(english[command.titleKey], command.rawValue)
        }
    }

    func testFormatStringsKeepTheirPlaceholders() throws {
        for language in AppLanguage.allCases {
            let strings = AppStrings(language: language)
            XCTAssertTrue(String(format: strings["dialog.from"], "example.com").contains("example.com"))
            XCTAssertTrue(String(format: strings["zoomLevel"], 125).contains("125"))
        }
    }

    func testUnknownLanguageFallsBackToEnglish() {
        XCTAssertEqual(AppStrings(rawValue: "xx")["newTab"], "New Tab")
    }
}
