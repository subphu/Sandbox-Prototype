//
//  Sandbox.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/02/24.
//


import Metal
import MetalKit
import simd

class Sandbox: NSObject, MTKViewDelegate {
    
    let renderer: Renderer
    let scenes: [Scene]
    let activeSceneIdx: Int = 0
    
    init(mtkView: MTKView) {
        renderer = Renderer(view: mtkView)
        scenes = [
            MainScene()
        ]
        scenes[activeSceneIdx].setup()
        super.init()
    }
    
    func draw(in view: MTKView) {
        renderer.draw(scenes[activeSceneIdx], in: view)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.resizeFrame(resolution: size)
    }
    
    var mousePos: CGPoint = .zero
    
    func tap(at point: CGPoint) {
        mousePos = point
    }
    
    func move(to point: CGPoint, invertY: Bool = false) {
        var delta = mousePos - point
        mousePos = point
        
        delta.y = invertY ? -delta.y : delta.y
        
        renderer.camera.move(direction: vector_float3(x: Float(delta.x), y: Float(delta.y), z: 0))
    }
    
    func zoom(delta: Float) {
        renderer.camera.move(direction: vector_float3(x: 0, y: 0, z: delta))
    }
}
