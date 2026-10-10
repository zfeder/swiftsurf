//
//  BrowserCommand.swift
//  swiftsurf
//

import SwiftUI

/// Every keyboard-driven browser action, shared by the app menus and the popover's own shortcuts.
enum BrowserCommand: String, CaseIterable {
    case newTab, reopenClosedTab, closeTab
    case focusAddress, find, findNext, findPrevious
    case reload, goBack, goForward, nextTab, previousTab
    case zoomIn, zoomOut, actualSize, toggleReader
    case toggleBookmark, showHistory, showDownloads

    var shortcut: KeyboardShortcut {
        switch self {
        case .newTab: KeyboardShortcut("t", modifiers: .command)
        case .reopenClosedTab: KeyboardShortcut("t", modifiers: [.command, .shift])
        case .closeTab: KeyboardShortcut("w", modifiers: .command)
        case .focusAddress: KeyboardShortcut("l", modifiers: .command)
        case .find: KeyboardShortcut("f", modifiers: .command)
        case .findNext: KeyboardShortcut("g", modifiers: .command)
        case .findPrevious: KeyboardShortcut("g", modifiers: [.command, .shift])
        case .reload: KeyboardShortcut("r", modifiers: .command)
        case .goBack: KeyboardShortcut("[", modifiers: .command)
        case .goForward: KeyboardShortcut("]", modifiers: .command)
        case .nextTab: KeyboardShortcut(.tab, modifiers: .control)
        case .previousTab: KeyboardShortcut(.tab, modifiers: [.control, .shift])
        case .zoomIn: KeyboardShortcut("=", modifiers: .command)
        case .zoomOut: KeyboardShortcut("-", modifiers: .command)
        case .actualSize: KeyboardShortcut("0", modifiers: .command)
        case .toggleReader: KeyboardShortcut("r", modifiers: [.command, .shift])
        case .toggleBookmark: KeyboardShortcut("d", modifiers: .command)
        case .showHistory: KeyboardShortcut("y", modifiers: [.command, .shift])
        case .showDownloads: KeyboardShortcut("l", modifiers: [.command, .option])
        }
    }

    /// Key in `AppStrings` for the menu title.
    var titleKey: String { "command.\(rawValue)" }

    func post() {
        NotificationCenter.default.post(name: .swiftSurfCommand, object: self)
    }
}

extension Notification.Name {
    static let swiftSurfCommand = Notification.Name("SwiftSurfCommand")
}
