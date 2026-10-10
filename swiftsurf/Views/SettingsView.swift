//
//  SettingsView.swift
//  swiftsurf
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        SettingsForm()
            .padding()
            .frame(width: 420, height: 560)
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
    @AppStorage(PreferenceKey.homePage) private var homePage = PreferenceDefault.homePage
    @AppStorage(PreferenceKey.showDockIcon) private var showDockIcon = true
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.systemDefault.rawValue
    @AppStorage(PreferenceKey.searchEngine) private var searchEngine = SearchEngine.google.rawValue
    @AppStorage(PreferenceKey.restoreSession) private var restoreSession = true
    @AppStorage(PreferenceKey.blockTrackers) private var blockTrackers = true
    @AppStorage(PreferenceKey.showFavoritesBar) private var showFavoritesBar = true
    @AppStorage(PreferenceKey.keepPopoverOpen) private var keepPopoverOpen = false
    @AppStorage(PreferenceKey.globalHotKey) private var globalHotKey = HotKeyPreset.optionSpace.rawValue

    private var strings: AppStrings { AppStrings(rawValue: appLanguage) }

    var body: some View {
        Form {
            Section(strings["settings.language"]) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            appLanguage = language.rawValue
                        } label: {
                            HStack {
                                Text(language.displayName)
                                Spacer()
                                if appLanguage == language.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }

            Section {
                TextField(strings["settings.homePage"], text: $homePage)
                    .textFieldStyle(.roundedBorder)
                Toggle(strings["settings.restoreSession"], isOn: $restoreSession)
                Picker(strings["settings.searchEngine"], selection: $searchEngine) {
                    ForEach(SearchEngine.allCases) { engine in
                        Text(engine.displayName).tag(engine.rawValue)
                    }
                }
            } header: {
                Text(strings["settings.startup"])
            } footer: {
                Text(strings["settings.homePageFooter"])
            }

            Section {
                Toggle(strings["settings.blockTrackers"], isOn: $blockTrackers)
            } header: {
                Text(strings["settings.privacy"])
            } footer: {
                Text(strings["settings.blockTrackersFooter"])
            }

            Section {
                Toggle(strings["settings.showDockIcon"], isOn: $showDockIcon)
                Toggle(strings["settings.favoritesBar"], isOn: $showFavoritesBar)
                Toggle(strings["keepOpen"], isOn: $keepPopoverOpen)
            } header: {
                Label(strings["settings.appearance"], systemImage: "macwindow")
            } footer: {
                Text(strings["settings.appearanceFooter"])
            }

            Section {
                Picker(strings["settings.globalShortcut"], selection: $globalHotKey) {
                    ForEach(HotKeyPreset.allCases) { preset in
                        Text(preset == .disabled ? strings["settings.off"] : preset.displayName)
                            .tag(preset.rawValue)
                    }
                }
            } header: {
                Label(strings["settings.keyboard"], systemImage: "keyboard")
            } footer: {
                Text(strings["settings.globalShortcutFooter"])
            }
        }
        .formStyle(.grouped)
    }
}
