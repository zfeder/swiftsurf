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
    var popover: ResizablePopover?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Browser")
            button.action = #selector(togglePopover)
        }

        setupPopover()
    }

    func setupPopover() {
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        
        popover = ResizablePopover()
        popover?.contentViewController = hostingController
        popover?.behavior = .transient
        popover?.contentSize = NSSize(width: 320, height: 480)
    }

    @objc func togglePopover() {
        if let button = statusBarItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}
