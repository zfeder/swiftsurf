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
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    var body: some Scene {
        // La scena delle impostazioni è definita qui.
        // Si aprirà solo se l'utente la richiede esplicitamente (es. tramite il menu dell'applicazione).
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(AppStrings(language: currentLanguage)["newTab"]) {
                    NotificationCenter.default.post(name: .swiftSurfNewTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)
            }
            CommandGroup(after: .textEditing) {
                Button(AppStrings(language: currentLanguage)["focusAddress"]) {
                    NotificationCenter.default.post(name: .swiftSurfFocusAddress, object: nil)
                }
                .keyboardShortcut("l", modifiers: .command)
                Button(AppStrings(language: currentLanguage)["showHistory"]) {
                    NotificationCenter.default.post(name: .swiftSurfShowHistory, object: nil)
                }
                .keyboardShortcut("y", modifiers: [.command, .shift])
            }
        }
    }

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }
}

extension Notification.Name {
    static let swiftSurfNewTab = Notification.Name("SwiftSurfNewTab")
    static let swiftSurfFocusAddress = Notification.Name("SwiftSurfFocusAddress")
    static let swiftSurfShowHistory = Notification.Name("SwiftSurfShowHistory")
    static let swiftSurfDockIconPreferenceChanged = Notification.Name("SwiftSurfDockIconPreferenceChanged")
    static let swiftSurfLanguageChanged = Notification.Name("SwiftSurfLanguageChanged")
}
