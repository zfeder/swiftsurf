//
//  Preferences.swift
//  swiftsurf
//

import Carbon.HIToolbox
import Foundation

/// UserDefaults keys shared by `@AppStorage` properties and AppKit code.
enum PreferenceKey {
    static let homePage = "homePage"
    static let appLanguage = "appLanguage"
    static let showDockIcon = "showDockIcon"
    static let searchEngine = "searchEngine"
    static let restoreSession = "restoreSession"
    static let blockTrackers = "blockTrackers"
    static let showFavoritesBar = "showFavoritesBar"
    static let keepPopoverOpen = "keepPopoverOpen"
    static let globalHotKey = "globalHotKey"
    static let pageZoom = "pageZoom"
    static let sessionTabs = "sessionTabs"
    static let sessionSelectedIndex = "sessionSelectedIndex"
}

enum PreferenceDefault {
    static let homePage = "https://www.google.com/"
}

extension UserDefaults {
    func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        object(forKey: key) as? Bool ?? defaultValue
    }

    var searchEngine: SearchEngine {
        string(forKey: PreferenceKey.searchEngine).flatMap(SearchEngine.init(rawValue:)) ?? .google
    }

    var homePage: String {
        string(forKey: PreferenceKey.homePage) ?? PreferenceDefault.homePage
    }
}

enum SearchEngine: String, CaseIterable, Identifiable {
    case google, duckDuckGo, bing, ecosia, startpage, kagi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: "Google"
        case .duckDuckGo: "DuckDuckGo"
        case .bing: "Bing"
        case .ecosia: "Ecosia"
        case .startpage: "Startpage"
        case .kagi: "Kagi"
        }
    }

    private var searchURLPrefix: String {
        switch self {
        case .google: "https://www.google.com/search?q="
        case .duckDuckGo: "https://duckduckgo.com/?q="
        case .bing: "https://www.bing.com/search?q="
        case .ecosia: "https://www.ecosia.org/search?q="
        case .startpage: "https://www.startpage.com/do/search?q="
        case .kagi: "https://kagi.com/search?q="
        }
    }

    func searchURL(for query: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?#")
        let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query
        return URL(string: searchURLPrefix + encoded)
    }
}

/// Global shortcuts that toggle the popover from any application.
enum HotKeyPreset: String, CaseIterable, Identifiable {
    case disabled
    case optionSpace
    case controlOptionSpace
    case commandShiftSpace
    case optionShiftS

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .disabled: "—"
        case .optionSpace: "⌥ Space"
        case .controlOptionSpace: "⌃⌥ Space"
        case .commandShiftSpace: "⇧⌘ Space"
        case .optionShiftS: "⌥⇧ S"
        }
    }

    /// Carbon virtual key code and modifier mask, or `nil` when disabled.
    var carbonShortcut: (keyCode: UInt32, modifiers: UInt32)? {
        switch self {
        case .disabled: nil
        case .optionSpace: (UInt32(kVK_Space), UInt32(optionKey))
        case .controlOptionSpace: (UInt32(kVK_Space), UInt32(controlKey | optionKey))
        case .commandShiftSpace: (UInt32(kVK_Space), UInt32(cmdKey | shiftKey))
        case .optionShiftS: (UInt32(kVK_ANSI_S), UInt32(optionKey | shiftKey))
        }
    }
}
