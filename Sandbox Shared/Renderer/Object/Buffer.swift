//
//  Buffer.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/27.
//

import Metal
import MetalKit
import simd

class Buffer {
    private let perFrame: Bool
    private let size: Int
    private let count: Int
    private var options: MTLResourceOptions = []
    private var buffer: MTLBuffer?
    
    init(size: Int, perFrame: Bool = false) {
        precondition(size > 0, "Buffer size must be bigger than zero.")
        // The 256 byte aligned size of our uniform structure
        self.size = roundUp(size)
        self.perFrame = perFrame
        self.count = perFrame ? FrameInfo.frameMax : 1
    }
    
    convenience init(constName: String, constSize: Int, perFrame: Bool = false) {
        self.init(size: constSize, perFrame: perFrame)
        self.set(options: [MTLResourceOptions.storageModeShared])
        self.create(name: constName)
    }
    
    convenience init(bufName: String, bufSize: Int, options: MTLResourceOptions = []) {
        self.init(size: bufSize)
        self.set(options: options)
        self.create(name: bufName)
    }
    
    func create(name: String) {
        buffer = Render.shared.device.makeBuffer(length: size * count, options: options)
        guard self.buffer != nil else { fatalError("Failed to create buffer \(name).") }
        buffer!.label = "Buffer \(name)"
    }
    
    func getPointer() -> UnsafeMutableRawPointer? {
        guard let buffer = self.buffer else { return nil }
        return UnsafeMutableRawPointer(buffer.contents() + getOffset())
    }
    
    func set(options: MTLResourceOptions) { self.options = options }
    
    func get() -> MTLBuffer? { return buffer }
    func getOffset() -> Int { return perFrame ? size * Render.shared.frameInfo.frameIdx : 0 }
}
