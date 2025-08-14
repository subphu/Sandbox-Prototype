//
//  Texture.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/27.
//

import Metal
import MetalKit
import simd

class Texture {
    private var name: String = ""
    private var options: [MTKTextureLoader.Option: Any] = [:]
    private var texture: MTLTexture?
    
    private let descriptor: MTLTextureDescriptor
    
    init() {
        descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type2D
        descriptor.storageMode = .private
        descriptor.arrayLength = 1
        descriptor.sampleCount = 1
        descriptor.mipmapLevelCount = 1
    }
    
    convenience init(_ name: String) {
        self.init()
        self.options = [
            .SRGB: false,
            .origin : MTKTextureLoader.Origin.bottomLeft,
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
        ]
        self.load(name: name)
    }
    
    convenience init(_ name: String, options: [MTKTextureLoader.Option: Any]) {
        self.init()
        self.options = options
        self.load(name: name)
    }
    
    convenience init(rtName: String, rtSize: CGSize, format: MTLPixelFormat = .rgba8Unorm) {
        self.init()
        self.descriptor.usage  = [.renderTarget, .shaderRead, .shaderWrite]
        self.descriptor.width  = Int(rtSize.width)
        self.descriptor.height = Int(rtSize.height)
        self.descriptor.pixelFormat = format
        self.texture = Render.shared.device.makeTexture(descriptor: descriptor)!
    }
    
    func load(name: String) {
        self.name = name
        do {
            texture = try Render.shared.textureLoader.newTexture(name: "\(name)",
                                                                 scaleFactor: 1.0,
                                                                 bundle: nil,
                                                                 options: options)
        } catch {
            print("Unable to load texture. Error info: \(error)")
        }
    }
    
    func resize(_ size: CGSize) {
        self.descriptor.width  = Int(size.width)
        self.descriptor.height = Int(size.height)
        self.texture = Render.shared.device.makeTexture(descriptor: descriptor)!
    }
    
    func set(options: [MTKTextureLoader.Option: Any]) { self.options = options }
    
    func get()           -> MTLTexture? { return texture }
    func getDescriptor() -> MTLTextureDescriptor { return descriptor }
    func getFormat()     -> MTLPixelFormat { return descriptor.pixelFormat }
    func getResolution() -> CGSize { return CGSize(width: descriptor.width, height: descriptor.height) }
}
