//
//  ResizablePopoverViewController.swift
//  swiftsurf
//
//  Created by Federico Filì on 13/07/24.
//

import Cocoa
import SwiftUI

class ResizablePopover: NSPopover {
    private var resizeHandle: NSView?
    private var isResizing = false
    
    override func show(relativeTo positioningRect: NSRect, of positioningView: NSView, preferredEdge: NSRectEdge) {
        super.show(relativeTo: positioningRect, of: positioningView, preferredEdge: preferredEdge)
        
        DispatchQueue.main.async {
            self.addResizeHandle()
        }
    }
    
    private func addResizeHandle() {
        guard let frameView = contentViewController?.view.window?.contentView?.superview,
              resizeHandle == nil else { return }
        
        let handle = NSView(frame: NSRect(x: frameView.bounds.width - 20, y: 0, width: 20, height: 20))
        handle.wantsLayer = true
        handle.layer?.backgroundColor = NSColor.clear.cgColor
        
        frameView.addSubview(handle)
        
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleResize(_:)))
        handle.addGestureRecognizer(panGesture)
        
        self.resizeHandle = handle
        
        updateResizeHandlePosition()
    }
    
    private func updateResizeHandlePosition() {
        guard let frameView = contentViewController?.view.window?.contentView?.superview,
              let handle = resizeHandle else { return }
        
        handle.frame.origin = CGPoint(x: frameView.bounds.width - 20, y: 0)
    }
    
    @objc func handleResize(_ gesture: NSPanGestureRecognizer) {
        guard let frameView = contentViewController?.view.window?.contentView?.superview,
              let contentView = contentViewController?.view else { return }
        
        switch gesture.state {
        case .began:
            isResizing = true
        case .changed:
            guard isResizing else { return }
            
            let translation = gesture.translation(in: frameView)
            var newSize = contentView.frame.size
            newSize.width += translation.x
            newSize.height -= translation.y
            
            newSize.width = max(newSize.width, 320)  // Minimum width
            newSize.height = max(newSize.height, 400)  // Minimum height
            
            contentSize = newSize
            contentViewController?.view.frame.size = newSize
            
            updateResizeHandlePosition()
            
            gesture.setTranslation(.zero, in: frameView)
        case .ended, .cancelled:
            isResizing = false
        default:
            break
        }
    }
}
