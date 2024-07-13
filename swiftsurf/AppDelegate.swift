//
//  AppDelegate.swift
//  Navigator
//
//  Created by Federico Filì on 12/07/24.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var popover: NSPopover?
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Browser")
            button.action = #selector(togglePopover)
        }

        let contentView = ContentView()
        let resizableController = ResizablePopoverViewController(rootView: contentView, initialSize: NSSize(width: 320, height: 480))
        
        popover = NSPopover()
        popover?.contentViewController = resizableController
        popover?.behavior = .applicationDefined
        popover?.animates = true
        popover?.contentSize = NSSize(width: 320, height: 480)
        
        NotificationCenter.default.addObserver(self, selector: #selector(popoverWillShow), name: NSPopover.willShowNotification, object: popover)
    }

    @objc func togglePopover() {
        guard let popover = popover, let statusBarButton = statusBarItem?.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func popoverWillShow(_ notification: Notification) {
        if let popover = notification.object as? NSPopover {
            popover.contentSize = NSSize(width: 320, height: 480)
        }
    }

    @objc func openSettings(_ sender: AnyObject?) {
        if settingsWindow == nil {
            let settingsView = SettingsView()
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "Settings"
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.contentView = NSHostingView(rootView: settingsView)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
