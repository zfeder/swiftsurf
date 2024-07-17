//
//  ResizablePopoverViewController.swift
//  swiftsurf
//
//  Created by Federico Filì on 13/07/24.
//

import Cocoa

class ResizablePopover: NSPopover {
    override func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        super.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
        
        DispatchQueue.main.async {
            self.addResizeHandle()
        }
    }
    
    private func addResizeHandle() {
        guard let frameView = contentViewController?.view.window?.contentView?.superview else { return }
        
        let resizeHandle = NSView(frame: NSRect(x: frameView.bounds.width - 20, y: 0, width: 20, height: 20))
        resizeHandle.wantsLayer = true
        resizeHandle.layer?.backgroundColor = NSColor.clear.cgColor
        
        let resizeImage = NSImageView(frame: resizeHandle.bounds)
        resizeImage.image = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: "Resize")
        resizeImage.contentTintColor = .gray
        resizeHandle.addSubview(resizeImage)
        
        frameView.addSubview(resizeHandle)
        
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleResize(_:)))
        resizeHandle.addGestureRecognizer(panGesture)
    }
    
    @objc func handleResize(_ gesture: NSPanGestureRecognizer) {
        guard let frameView = contentViewController?.view.window?.contentView?.superview,
              let contentView = contentViewController?.view else { return }
        
        let translation = gesture.translation(in: frameView)
        var newSize = contentView.frame.size
        newSize.width += translation.x
        newSize.height -= translation.y
        
        newSize.width = max(newSize.width, 320)  // Minimum width
        newSize.height = max(newSize.height, 400)  // Minimum height
        
        contentSize = newSize
        contentViewController?.view.frame.size = newSize
        
        if let resizeHandle = gesture.view {
            resizeHandle.frame.origin = CGPoint(x: newSize.width - 20, y: 0)
        }
        
        gesture.setTranslation(.zero, in: frameView)
    }
}
