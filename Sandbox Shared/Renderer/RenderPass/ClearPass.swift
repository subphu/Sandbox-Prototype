//
//  ClearPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/26.
//

import Metal
import MetalKit
import simd

class ClearPass: RenderPass {
    private(set) var id: RenderPassId = .ClearPass
    private(set) var descriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
     
    init() {
    }
    
    func setup() {
    }
    
    func update(context: RenderContext) {
        descriptor.colorAttachments[0] = Render.shared.frameInfo.colorAttachment
        descriptor.colorAttachments[0].loadAction = .clear
        
        descriptor.depthAttachment = Render.shared.frameInfo.depthAttachment
        descriptor.depthAttachment.loadAction = .clear
        
        descriptor.stencilAttachment = Render.shared.frameInfo.stencilAttachment
        descriptor.stencilAttachment.loadAction = .clear
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
        context.addCommand(to: id, priority: 0) { encoder in }
    }
    
    func globalBind(to encoder: any MTLRenderCommandEncoder) {        
    }
    
}

