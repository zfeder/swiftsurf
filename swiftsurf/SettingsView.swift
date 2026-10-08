//
//  SettingsView.swift
//  swiftsurf
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("homePage") private var homePage = "https://www.google.com/"

    var body: some View {
        Form {
            Section {
                TextField("Home page URL", text: $homePage)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Label("Startup", systemImage: "house")
            } footer: {
                Text("This page opens whenever SwiftSurf starts a new session.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 380, height: 170)
    }
}
