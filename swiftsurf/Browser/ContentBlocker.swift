//
//  ContentBlocker.swift
//  swiftsurf
//

import Foundation
import WebKit

/// Compiles a WebKit content rule list that blocks well-known third-party ad and tracking hosts.
final class ContentBlocker {
    static let shared = ContentBlocker()

    static let identifier = "SwiftSurfTrackerBlocklist-v1"

    static let blockedDomains = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com", "google-analytics.com",
        "googletagmanager.com", "googletagservices.com", "adservice.google.com", "app-measurement.com",
        "facebook.net", "ads-twitter.com", "analytics.twitter.com",
        "ads.linkedin.com", "bat.bing.com", "clarity.ms",
        "scorecardresearch.com", "quantserve.com", "hotjar.com", "mouseflow.com", "fullstory.com",
        "mixpanel.com", "segment.io", "cdn.segment.com", "amplitude.com", "newrelic.com", "nr-data.net",
        "criteo.com", "criteo.net", "taboola.com", "outbrain.com", "adnxs.com", "rubiconproject.com",
        "pubmatic.com", "openx.net", "casalemedia.com", "advertising.com", "adsrvr.org", "moatads.com",
        "amazon-adsystem.com", "media.net", "zedo.com", "yieldmo.com", "sharethrough.com", "smartadserver.com",
        "chartbeat.com", "chartbeat.net", "krxd.net", "bluekai.com", "demdex.net", "omtrdc.net",
        "everesttech.net", "tiqcdn.com", "branch.io", "adform.net", "teads.tv", "exelator.com"
    ]

    /// The rule list encoded as WebKit content blocker JSON.
    static var encodedRules: String {
        let rules: [[String: Any]] = blockedDomains.map { domain in
            let escaped = NSRegularExpression.escapedPattern(for: domain)
            return [
                "trigger": [
                    "url-filter": "^[a-z]+://([^/:]+\\.)?\(escaped)[:/]",
                    "load-type": ["third-party"]
                ],
                "action": ["type": "block"]
            ]
        }
        let data = (try? JSONSerialization.data(withJSONObject: rules)) ?? Data("[]".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    private(set) var ruleList: WKContentRuleList?
    private var pendingCompletions: [(WKContentRuleList?) -> Void] = []
    private var isCompiling = false

    /// Calls `completion` on the main queue with the compiled list, compiling it the first time.
    func load(_ completion: @escaping (WKContentRuleList?) -> Void) {
        if let ruleList {
            completion(ruleList)
            return
        }
        pendingCompletions.append(completion)
        guard !isCompiling else { return }
        isCompiling = true

        let store = WKContentRuleListStore.default()
        store?.lookUpContentRuleList(forIdentifier: Self.identifier) { [weak self] list, _ in
            if let list {
                self?.finish(list)
            } else {
                store?.compileContentRuleList(forIdentifier: Self.identifier,
                                              encodedContentRuleList: Self.encodedRules) { list, error in
                    if let error {
                        NSLog("SwiftSurf content blocker error: %@", error.localizedDescription)
                    }
                    self?.finish(list)
                }
            }
        }
    }

    private func finish(_ list: WKContentRuleList?) {
        DispatchQueue.main.async {
            self.ruleList = list
            self.isCompiling = false
            let completions = self.pendingCompletions
            self.pendingCompletions.removeAll()
            completions.forEach { $0(list) }
        }
    }
}
