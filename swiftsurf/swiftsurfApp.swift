//
//  swiftsurfApp.swift
//  swiftsurf
//
//  Created by Federico Filì on 12/07/24.
//

import SwiftUI

@main
struct swiftsurfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // La scena delle impostazioni è definita qui.
        // Si aprirà solo se l'utente la richiede esplicitamente (es. tramite il menu dell'applicazione).
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    NotificationCenter.default.post(name: .swiftSurfNewTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            CommandGroup(after: .textEditing) {
                Button("Focus Address Bar") {
                    NotificationCenter.default.post(name: .swiftSurfFocusAddress, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
                Button("Show History") {
                    NotificationCenter.default.post(name: .swiftSurfShowHistory, object: nil)
                }
                .keyboardShortcut("y", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let swiftSurfNewTab = Notification.Name("SwiftSurfNewTab")
    static let swiftSurfFocusAddress = Notification.Name("SwiftSurfFocusAddress")
    static let swiftSurfShowHistory = Notification.Name("SwiftSurfShowHistory")
    static let swiftSurfDockIconPreferenceChanged = Notification.Name("SwiftSurfDockIconPreferenceChanged")
}
