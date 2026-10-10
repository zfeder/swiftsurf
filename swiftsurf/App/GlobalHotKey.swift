//
//  GlobalHotKey.swift
//  swiftsurf
//

import Carbon.HIToolbox

/// A system-wide keyboard shortcut. Carbon hot keys work in the sandbox without Accessibility access.
final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    deinit {
        unregister()
    }

    /// Replaces the current shortcut; `nil` disables it. Returns `false` if another app owns the shortcut.
    @discardableResult
    func register(_ shortcut: (keyCode: UInt32, modifiers: UInt32)?) -> Bool {
        unregister()
        guard let shortcut else { return true }

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { hotKey.action() }
            return noErr
        }, 1, &eventType, context, &handlerRef)

        let hotKeyID = EventHotKeyID(signature: OSType(0x5353_5246), id: 1) // "SSRF"
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        return status == noErr
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }
}
