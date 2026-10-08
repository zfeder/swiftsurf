//
//  AppDelegate.swift
//  swiftsurf
//

import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem?
    private var browserPopover: ResizablePopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Open SwiftSurf")
            button.image?.isTemplate = true
            button.toolTip = "Open SwiftSurf"
            button.action = #selector(togglePopover)
            button.target = self
        }

        let popover = ResizablePopover()
        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = ResizablePopover.savedContentSize
        browserPopover = popover
    }

    @objc private func togglePopover() {
        guard let button = statusBarItem?.button, let popover = browserPopover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
