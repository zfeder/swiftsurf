//
//  AppDelegate.swift
//  swiftsurf
//

import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var showsDockIcon: Bool?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let applicationIcon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = applicationIcon
        }
        applyDockIconVisibility()
        menuBarController = MenuBarController(rootView: ContentView())

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    @objc private func preferencesChanged(_ notification: Notification) {
        applyDockIconVisibility()
        menuBarController?.applyPreferences()
    }

    private func applyDockIconVisibility() {
        let showDockIcon = UserDefaults.standard.bool(forKey: PreferenceKey.showDockIcon, default: true)
        guard showDockIcon != showsDockIcon else { return }
        showsDockIcon = showDockIcon
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
    }
}
