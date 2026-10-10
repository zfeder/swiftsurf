//
//  MenuBarController.swift
//  swiftsurf
//

import Cocoa
import SwiftUI

/// Owns the status item, the browser popover and the global shortcut that toggles it.
final class MenuBarController: NSObject, NSPopoverDelegate {
    private static weak var current: MenuBarController?

    private let statusItem: NSStatusItem
    private let popover = ResizablePopover()
    private var hotKey: GlobalHotKey?
    private var registeredHotKey: HotKeyPreset?
    private var openHolds = 0

    init<Content: View>(rootView: Content) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        Self.current = self

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Open SwiftSurf")
            button.image?.isTemplate = true
            button.toolTip = "SwiftSurf"
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.animates = true
        popover.contentSize = ResizablePopover.savedContentSize
        popover.delegate = self
        hotKey = GlobalHotKey { [weak self] in self?.toggleFromHotKey() }
        applyPreferences()
    }

    /// Re-reads the "keep open" and global shortcut preferences.
    func applyPreferences() {
        updatePopoverBehavior()
        let preset = UserDefaults.standard.string(forKey: PreferenceKey.globalHotKey)
            .flatMap(HotKeyPreset.init(rawValue:)) ?? .optionSpace
        if preset != registeredHotKey {
            registeredHotKey = preset
            if hotKey?.register(preset.carbonShortcut) == false {
                NSLog("SwiftSurf: the shortcut %@ is already in use", preset.displayName)
            }
        }
    }

    /// Keeps a transient popover open while `body` shows a panel, until `body` calls its completion.
    static func keepPopoverOpen(_ body: (_ done: @escaping () -> Void) -> Void) {
        guard let controller = current else {
            body {}
            return
        }
        controller.openHolds += 1
        controller.updatePopoverBehavior()
        body { [weak controller] in
            guard let controller else { return }
            controller.openHolds -= 1
            controller.updatePopoverBehavior()
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            show()
        }
    }

    private func toggleFromHotKey() {
        if popover.isShown && NSApp.isActive {
            popover.performClose(nil)
        } else {
            show()
            BrowserCommand.focusAddress.post()
        }
    }

    private func show() {
        if !popover.isShown, let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func updatePopoverBehavior() {
        let keepOpen = UserDefaults.standard.bool(forKey: PreferenceKey.keepPopoverOpen)
        popover.behavior = keepOpen || openHolds > 0 ? .applicationDefined : .transient
    }

    // MARK: NSPopoverDelegate

    /// Dragging the popover away from the menu bar turns it into a floating window.
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        true
    }
}
