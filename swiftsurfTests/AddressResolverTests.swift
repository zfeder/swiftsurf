//
//  AddressResolverTests.swift
//  swiftsurfTests
//

import XCTest
@testable import swiftsurf

final class AddressResolverTests: XCTestCase {
    private func resolve(_ input: String, engine: SearchEngine = .google) -> String? {
        AddressResolver.url(for: input, searchEngine: engine)?.absoluteString
    }

    func testEmptyInputResolvesToNothing() {
        XCTAssertNil(resolve(""))
        XCTAssertNil(resolve("   \n"))
    }

    func testURLsWithSchemeAreKept() {
        XCTAssertEqual(resolve("https://swift.org/blog"), "https://swift.org/blog")
        XCTAssertEqual(resolve("  http://example.com  "), "http://example.com")
        XCTAssertEqual(resolve("about:blank"), "about:blank")
    }

    func testDomainsGetHTTPS() {
        XCTAssertEqual(resolve("apple.com"), "https://apple.com")
        XCTAssertEqual(resolve("developer.apple.com/documentation"), "https://developer.apple.com/documentation")
        XCTAssertEqual(resolve("my-site.co.uk:8443/path?q=1"), "https://my-site.co.uk:8443/path?q=1")
    }

    func testLocalAddressesGetHTTP() {
        XCTAssertEqual(resolve("localhost"), "http://localhost")
        XCTAssertEqual(resolve("localhost:3000"), "http://localhost:3000")
        XCTAssertEqual(resolve("127.0.0.1:8080/api"), "http://127.0.0.1:8080/api")
        XCTAssertEqual(resolve("192.168.1.10"), "http://192.168.1.10")
        XCTAssertEqual(resolve("printer.local"), "http://printer.local")
    }

    func testEverythingElseIsSearched() {
        XCTAssertEqual(resolve("swift concurrency"), "https://www.google.com/search?q=swift%20concurrency")
        XCTAssertEqual(resolve("3.14"), "https://www.google.com/search?q=3.14")
        XCTAssertEqual(resolve("999.1.1.1"), "https://www.google.com/search?q=999.1.1.1")
        XCTAssertEqual(resolve("hello"), "https://www.google.com/search?q=hello")
        XCTAssertEqual(resolve("localhost:99999"), "https://www.google.com/search?q=localhost:99999")
    }

    func testSearchQueriesEscapeReservedCharacters() {
        XCTAssertEqual(resolve("c++ & swift", engine: .duckDuckGo),
                       "https://duckduckgo.com/?q=c%2B%2B%20%26%20swift")
        XCTAssertEqual(resolve("a=b?#", engine: .bing), "https://www.bing.com/search?q=a%3Db%3F%23")
    }

    func testEverySearchEngineProducesAURL() {
        for engine in SearchEngine.allCases {
            XCTAssertNotNil(engine.searchURL(for: "test query"), engine.rawValue)
        }
    }
}
