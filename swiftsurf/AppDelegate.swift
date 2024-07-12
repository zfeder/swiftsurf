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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Browser")
            button.action = #selector(togglePopover(_:))
        }

        let contentView = ContentView()
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true) // Ensure the popover is active
            }
        }
    }
}
