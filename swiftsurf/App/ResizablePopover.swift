//
//  ResizablePopover.swift
//  swiftsurf
//

import Cocoa
import SwiftUI

final class ResizablePopover: NSPopover {
    static weak var activePopover: ResizablePopover?
    static let minimumContentSize = NSSize(width: 420, height: 480)
    static let maximumContentSize = NSSize(width: 1_200, height: 1_000)
    private static let savedWidthKey = "popoverWidth"
    private static let savedHeightKey = "popoverHeight"

    static var savedContentSize: NSSize {
        let defaults = UserDefaults.standard
        let width = defaults.double(forKey: savedWidthKey)
        let height = defaults.double(forKey: savedHeightKey)
        guard width > 0, height > 0 else { return NSSize(width: 680, height: 720) }
        return NSSize(width: width, height: height)
    }

    override var contentSize: NSSize {
        get { super.contentSize }
        set {
            let size = NSSize(
                width: min(max(newValue.width, Self.minimumContentSize.width), Self.maximumContentSize.width),
                height: min(max(newValue.height, Self.minimumContentSize.height), Self.maximumContentSize.height)
            )
            super.contentSize = size
            UserDefaults.standard.set(size.width, forKey: Self.savedWidthKey)
            UserDefaults.standard.set(size.height, forKey: Self.savedHeightKey)
        }
    }

    override func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        Self.activePopover = self
        super.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
    }

    override func performClose(_ sender: Any?) {
        super.performClose(sender)
        if Self.activePopover === self {
            Self.activePopover = nil
        }
    }
}

struct ResizeHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizeHandleView {
        ResizeHandleView()
    }

    func updateNSView(_ nsView: ResizeHandleView, context: Context) {}
}

final class ResizeHandleView: NSView {
    private var initialMouseLocation: NSPoint = .zero
    private var initialContentSize: NSSize = .zero

    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        guard let popover = ResizablePopover.activePopover else { return }
        initialMouseLocation = event.locationInWindow
        initialContentSize = popover.contentSize
    }

    override func mouseDragged(with event: NSEvent) {
        guard let popover = ResizablePopover.activePopover else { return }

        let location = event.locationInWindow
        let delta = NSPoint(
            x: location.x - initialMouseLocation.x,
            y: location.y - initialMouseLocation.y
        )

        popover.contentSize = NSSize(
            width: initialContentSize.width + delta.x,
            height: initialContentSize.height - delta.y
        )
    }

}
