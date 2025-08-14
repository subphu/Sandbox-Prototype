//
//  Commander.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/02/23.
//

import Metal
import MetalKit
import simd

class Commander {
    
    private enum cmdState {
        case idle
        case recording
        case submitted
    }
    
    private let cmdQueue: MTLCommandQueue
    private var cmdBuffer: MTLCommandBuffer!
    private let semaphores = DispatchSemaphore(value: 3)
    
    private var state: cmdState = .idle
    
    init() {
        self.cmdQueue = Render.shared.device.makeCommandQueue()!
    }
    
    func begin() {
        precondition(state == .idle, "Cannot begin commander: already in progress.")
        
        _ = semaphores.wait(timeout: DispatchTime.distantFuture)
        cmdBuffer = cmdQueue.makeCommandBuffer()
        cmdBuffer.addCompletedHandler { (_ commandBuffer)-> Swift.Void in self.semaphores.signal() }
        
        state = .recording
    }
    
    func end() {
        precondition(state != .idle, "Cannot end commander: no command in progress.")
        cmdBuffer.commit()
        state = .idle
    }
    
    func present(in view: MTKView) {
        precondition(state != .idle, "Cannot present frame: no command in progress.")
        guard let drawable = view.currentDrawable else { return }
        cmdBuffer.present(drawable)
    }

    func makeRenderCommandEncoder(descriptor: MTLRenderPassDescriptor) -> MTLRenderCommandEncoder? {
        return cmdBuffer.makeRenderCommandEncoder(descriptor: descriptor)
    }
}
