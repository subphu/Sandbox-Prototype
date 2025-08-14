//
//  GBufferPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/16.
//

import Metal
import MetalKit
import simd

class GBufferPass: RenderPass {
    static let formats: [MTLPixelFormat] = [.rgba8Unorm, .rgba8Unorm, .rgba8Unorm]
    
    private(set) var id: RenderPassId = .GBufferPass
    private(set) var descriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
    
    private let mainPipeline: Pipeline = Pipeline()    
    private var gbuffer: [Texture] = []
    
    init() {
    }
    
    func setup() {
        mainPipeline.setupDepthStencil()
        mainPipeline.setupColor(formats: GBufferPass.formats)
        
        let resolution = Render.shared.frameInfo.texture.getResolution()
        for i in 0..<GBufferPass.formats.count {
            gbuffer.append(Texture(rtName: "Gbuffer\(i)", rtSize: resolution, format: GBufferPass.formats[i]))
            descriptor.colorAttachments[i].texture = gbuffer[i].get()
            descriptor.colorAttachments[i].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
            descriptor.colorAttachments[i].loadAction = .dontCare
            descriptor.colorAttachments[i].storeAction = .store
        }
        
        descriptor.depthAttachment = Render.shared.frameInfo.depthAttachment
        descriptor.stencilAttachment = Render.shared.frameInfo.stencilAttachment
    }
    
    func update(context: RenderContext) {
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
        context.addCommand(to: id, priority: 0) { encoder in
            encoder.setStencilReferenceValue(StencilValue.GBuffer.rawValue)
        }
    }
    
    func globalBind(to encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup("GlobalBind: GBuffer")
        for i in 0..<GBufferPass.formats.count {
            encoder.setFragmentTexture(gbuffer[i].get(), index: TexIdx.gbuffer.rawValue + i)
        }
        encoder.popDebugGroup()
    }
    
    func getPipeline() -> Pipeline { return mainPipeline }
}
