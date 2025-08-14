//
//  GameViewController.swift
//  Sandbox iOS
//
//  Created by Subroto Hudiono on 2025/08/14.
//

import UIKit
import MetalKit

// Our iOS specific view controller
class GameViewController: UIViewController {

    var sandbox: Sandbox!
    var mtkView: MTKView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let mtkView = self.view as? MTKView else {
            print("View of Gameview controller is not an MTKView")
            return
        }

        sandbox = Sandbox(mtkView: mtkView)
        sandbox.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        mtkView.delegate = sandbox
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        mtkView.addGestureRecognizer(pinchRecognizer)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: view)
            sandbox.tap(at: location)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: view)
            sandbox.move(to: location, invertY: true)
        }
    }

    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        let delta = Float(recognizer.velocity)
        sandbox.zoom(delta: delta * 4)
    }
}
