//
//  ResizablePopover.swift
//  swiftsurf
//
//  Created by Federico Filì on 12/07/24.
//

import SwiftUI

struct ResizableHandle: NSViewRepresentable {
    class Coordinator: NSObject {
        var parent: ResizableHandle
        var initialLocation: NSPoint?
        var initialSize: NSSize?

        init(parent: ResizableHandle) {
            self.parent = parent
        }

        @objc func mouseDown(with event: NSEvent) {
            guard let window = NSApplication.shared.keyWindow else { return }
            initialLocation = event.locationInWindow
            initialSize = window.frame.size
        }

        @objc func mouseDragged(with event: NSEvent) {
            guard let window = NSApplication.shared.keyWindow,
                  let initialLocation = initialLocation,
                  let initialSize = initialSize else { return }

            let newLocation = event.locationInWindow
            let dx = newLocation.x - initialLocation.x
            let dy = initialLocation.y - newLocation.y

            var newFrame = window.frame
            newFrame.size.width = max(initialSize.width + dx, 200) // Minimum width
            newFrame.size.height = max(initialSize.height + dy, 200) // Minimum height

            window.setFrame(newFrame, display: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        let trackingArea = NSTrackingArea(rect: view.bounds, options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved], owner: context.coordinator, userInfo: nil)
        view.addTrackingArea(trackingArea)

        let panRecognizer = NSPanGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.mouseDragged(with:)))
        view.addGestureRecognizer(panRecognizer)

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let layer = nsView.layer {
            layer.cornerRadius = 5
            layer.borderColor = NSColor.black.cgColor
            layer.borderWidth = 1
        }
    }
}
