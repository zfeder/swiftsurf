//
//  AddressResolver.swift
//  swiftsurf
//

import Foundation

/// Turns whatever the user typed in the address bar into a URL to load.
enum AddressResolver {
    static func url(for input: String, searchEngine: SearchEngine) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if hasScheme(trimmed) {
            return URL(string: trimmed)
        }
        if !trimmed.contains(" "), let host = hostPart(of: trimmed) {
            if isLocalHost(host) || isIPv4Address(host) {
                return URL(string: "http://" + trimmed)
            }
            if isDomainName(host) {
                return URL(string: "https://" + trimmed)
            }
        }
        return searchEngine.searchURL(for: trimmed)
    }

    private static func hasScheme(_ text: String) -> Bool {
        if text.hasPrefix("about:") || text.hasPrefix("data:") { return true }
        guard let range = text.range(of: "://") else { return false }
        let scheme = text[..<range.lowerBound]
        guard let first = scheme.first, first.isLetter else { return false }
        return scheme.allSatisfy { $0.isLetter || $0.isNumber || "+-.".contains($0) }
    }

    /// The host without port, path, query or fragment, or `nil` if the port is malformed.
    private static func hostPart(of text: String) -> String? {
        let authority = text.prefix { !"/?#".contains($0) }
        let components = authority.split(separator: ":", omittingEmptySubsequences: false)
        guard components.count <= 2, let host = components.first, !host.isEmpty else { return nil }
        if components.count == 2 {
            guard let port = Int(components[1]), (1...65_535).contains(port) else { return nil }
        }
        return host.lowercased()
    }

    private static func isLocalHost(_ host: String) -> Bool {
        host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local")
    }

    private static func isIPv4Address(_ host: String) -> Bool {
        let parts = host.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 4 && parts.allSatisfy { part in
            guard let value = Int(part), String(value) == part else { return false }
            return (0...255).contains(value)
        }
    }

    private static func isDomainName(_ host: String) -> Bool {
        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        guard labels.count >= 2, let tld = labels.last, tld.count >= 2,
              tld.allSatisfy({ $0.isLetter }) else { return false }
        return labels.allSatisfy { label in
            !label.isEmpty && !label.hasPrefix("-") && !label.hasSuffix("-")
                && label.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" }
        }
    }
}
