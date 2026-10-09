//
//  SettingsView.swift
//  swiftsurf
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsForm()
            .padding()
            .frame(width: 380, height: 280)
    }
}

struct SettingsTabView: View {
    var body: some View {
        SettingsForm()
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 520, maxHeight: .infinity, alignment: .top)
    }
}

private struct SettingsForm: View {
    @AppStorage("homePage") private var homePage = "https://www.google.com/"
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.english.rawValue

    var body: some View {
        Form {
            Section("Language") {
                Picker("Interface language", selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
            }
            Section("Startup") {
                TextField("Home page URL", text: $homePage)
                .textFieldStyle(.roundedBorder)
                Text("This page opens whenever SwiftSurf starts a new session.")
                .foregroundStyle(.secondary)
                .font(.caption)
            }

            Section {
                Toggle("Show icon in Dock", isOn: $showDockIcon)
                .onChange(of: showDockIcon) { _, value in
                    NotificationCenter.default.post(
                        name: .swiftSurfDockIconPreferenceChanged,
                        object: value
                    )
                }
            } header: {
                Label("Appearance", systemImage: "macwindow")
            } footer: {
                Text("When disabled, SwiftSurf stays available from the menu bar without an icon in the Dock.")
            }
        }
        .formStyle(.grouped)
    }
}
