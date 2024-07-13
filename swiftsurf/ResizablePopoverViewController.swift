//
//  ResizablePopoverViewController.swift
//  swiftsurf
//
//  Created by Federico Filì on 13/07/24.
//

import Cocoa
import SwiftUI

class ResizablePopoverViewController: NSViewController {
    var hostingController: NSHostingController<ContentView>
    var initialSize: NSSize
    
    init(rootView: ContentView, initialSize: NSSize) {
        self.hostingController = NSHostingController(rootView: rootView)
        self.initialSize = initialSize
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(origin: .zero, size: initialSize))
        view.wantsLayer = true
        view.layer?.cornerRadius = 10
        view.layer?.masksToBounds = true
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.width, .height]
        
        let resizeHandle = NSView(frame: NSRect(x: view.frame.width - 20, y: 0, width: 20, height: 20))
        resizeHandle.wantsLayer = true
        resizeHandle.layer?.backgroundColor = NSColor.clear.cgColor
        view.addSubview(resizeHandle)
        
        let panGesture = NSPanGestureRecognizer(target: self, action: #selector(handleResize(_:)))
        resizeHandle.addGestureRecognizer(panGesture)
    }
    
    @objc func handleResize(_ gesture: NSPanGestureRecognizer) {
        guard let popover = view.window?.attachedSheet as? NSPopover else { return }
        
        let translation = gesture.translation(in: view)
        var newSize = view.frame.size
        newSize.width += translation.x
        newSize.height -= translation.y
        
        newSize.width = max(newSize.width, 320)  // Minimum width
        newSize.height = max(newSize.height, 400)  // Minimum height
        
        popover.contentSize = newSize
        view.frame.size = newSize
        hostingController.view.frame = view.bounds
        
        gesture.setTranslation(.zero, in: view)
        
        print("Resizing: width = \(newSize.width), height = \(newSize.height)")  // Debug print
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.becomeKey()
    }
}
