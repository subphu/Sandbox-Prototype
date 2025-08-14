//
//  LightingPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/21.
//

import Metal
import MetalKit
import simd

class LightingPass: RenderPass {
    private(set) var id: RenderPassId = .LightingPass
    private(set) var descriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
     
    private let pipeline: Pipeline = Pipeline()
    
    init() {
    }
    
    func setup() {
        pipeline.setupStencilCheck()
        pipeline.setupColor(formats: [Render.shared.frameInfo.format])
        pipeline.createState("\(self.id)", screenShaderName: "fs_lighting")
    }
    
    func update(context: RenderContext) {
        descriptor.colorAttachments[0] = Render.shared.frameInfo.colorAttachment
        descriptor.stencilAttachment = Render.shared.frameInfo.stencilAttachment
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
        context.addCommand(to: id, priority: 0) { encoder in
            self.pipeline.bind(encoder: encoder)
            encoder.setStencilReferenceValue(StencilValue.GBuffer.rawValue)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 3)
        }
    }
    
    func globalBind(to encoder: any MTLRenderCommandEncoder) {
        
    }
    
}
