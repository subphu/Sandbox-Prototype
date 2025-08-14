//
//  Renderer.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/02/23.
//

import Metal
import MetalKit
import simd

enum RenderPassId: Int {
    case ClearPass
    case PreComputePass
    case ZPrePass
    case GBufferPass
    case ShadowPass
    case LightingPass
    case ForwardPass
    case PostProcessPass
    case UIPass
    case DisplayPass
}

class Renderer {
    
    let device: MTLDevice
    let library: MTLLibrary
    let view: MTKView
    
    let meshAllocator: MTKMeshBufferAllocator
    let textureLoader: MTKTextureLoader
    
    var commander: Commander!
    var frameInfo: FrameInfo!
    
    var renderPassDict: [RenderPassId: RenderPass]!
    var renderPasses: [RenderPass]!
    
    var context: RenderContext!
       
    var camera: Camera!
    var lights: Lights!
    
    init(view: MTKView) {
        self.device = MTLCreateSystemDefaultDevice()!
        self.library = device.makeDefaultLibrary()!
        self.meshAllocator = MTKMeshBufferAllocator(device: device)
        self.textureLoader = MTKTextureLoader(device: device)
        
        self.view = view
        self.view.device = device
        
        Render.set(self)
        reset()
    }
    
    func reset() {
        camera = Camera()
        lights = Lights()
        commander = Commander()
        frameInfo = FrameInfo(resolution: view.drawableSize)

        renderPassDict = [
            .ClearPass: ClearPass(),
            .GBufferPass: GBufferPass(),
            .LightingPass: LightingPass(),
            .PostProcessPass: PostProcessPass(),
            .UIPass: UIPass(),
            .DisplayPass: DisplayPass()
        ]
        renderPasses = renderPassDict.sorted { $0.key.rawValue < $1.key.rawValue }.map { $0.value }
        renderPasses.forEach { pass in pass.setup() }

        context = RenderContext()
    }
    
    func draw(_ scene: Scene, in: MTKView) {
        context.prepareFrame()
        frameInfo.prepareFrame()
        commander.begin()
        
        renderPasses.forEach { pass in pass.update(context: context) }
        scene.update(context: context)
        
        lights.update()
        context.setGlobalCommand() { encoder in
            self.frameInfo.globalBind(to: encoder)
            self.lights.globalBind(to: encoder)
            self.renderPasses.forEach { $0.globalBind(to: encoder) }
        }
        
        renderPasses.forEach { pass in pass.draw(context: context) }
        scene.draw(context: context)
        
        context.executeRecords()
        
        commander.present(in: view)
        commander.end()
    }
    
    func resizeFrame(resolution: CGSize) {
        frameInfo.setResolution(resolution)
        renderPasses.forEach { pass in pass.setup() }
    }
    
}

