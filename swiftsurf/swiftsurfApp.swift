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
    }
}
