//
//  GameViewController.swift
//  Sandbox macOS
//
//  Created by Subroto Hudiono on 2025/08/14.
//

import Cocoa
import MetalKit

// Our macOS specific view controller
class GameViewController: NSViewController {

    var sandbox: Sandbox!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View attached to GameViewController is not an MTKView")
            return
        }
        
        sandbox = Sandbox(mtkView: mtkView)
        sandbox.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = sandbox
        
        view.window?.makeFirstResponder(self)
    }
    
    override func mouseDown(with event: NSEvent) {
        sandbox.tap(at: event.locationInWindow)
    }
    
    override func mouseDragged(with event: NSEvent) {
        sandbox.move(to: event.locationInWindow)
    }
    
    override func scrollWheel(with event: NSEvent) {
        sandbox.zoom(delta: Float(event.scrollingDeltaY))
    }
}
