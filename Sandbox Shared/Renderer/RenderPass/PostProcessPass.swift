//
//  PostProcessPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/13.
//

import Metal
import MetalKit
import simd

class PostProcessPass: RenderPass {
    private(set) var id: RenderPassId = .PostProcessPass
    private(set) var descriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
     
    init() {
    }
    
    func setup() {
    }
    
    func update(context: RenderContext) {
        descriptor.colorAttachments[0] = Render.shared.frameInfo.colorAttachment
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
    }
    
    func globalBind(to encoder: any MTLRenderCommandEncoder) {
        
    }
    
}
