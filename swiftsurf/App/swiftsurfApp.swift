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
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.systemDefault.rawValue

    var body: some Scene {
        // The browser lives in the menu bar popover; this scene only backs the app menu and ⌘,.
        Settings {
            SettingsView()
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button(strings["quit"]) {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            // ⌘W stays with the popover's own shortcuts so it still closes the Settings window.
            CommandGroup(replacing: .newItem) {
                commandButtons(.newTab, .reopenClosedTab)
            }
            CommandGroup(after: .textEditing) {
                commandButtons(.focusAddress, .find, .findNext, .findPrevious)
            }
            CommandMenu(strings["menu.view"]) {
                commandButtons(.reload, .toggleReader)
                Divider()
                commandButtons(.zoomIn, .zoomOut, .actualSize)
            }
            CommandMenu(strings["menu.navigate"]) {
                commandButtons(.goBack, .goForward)
                Divider()
                commandButtons(.nextTab, .previousTab)
                Divider()
                commandButtons(.toggleBookmark, .showHistory, .showDownloads)
            }
        }
    }

    private var strings: AppStrings {
        AppStrings(rawValue: appLanguage)
    }

    private func commandButtons(_ commands: BrowserCommand...) -> some View {
        ForEach(commands, id: \.self) { command in
            Button(strings[command.titleKey]) { command.post() }
                .keyboardShortcut(command.shortcut)
        }
    }
}
