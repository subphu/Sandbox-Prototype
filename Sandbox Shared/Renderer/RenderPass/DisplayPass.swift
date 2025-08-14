//
//  DisplayPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/02/24.
//

import Metal
import MetalKit
import simd

class DisplayPass: RenderPass {
    private(set) var id: RenderPassId = .DisplayPass
    
    private let pipeline: Pipeline = Pipeline()
    
    var descriptor: MTLRenderPassDescriptor { get { return Render.shared.view.currentRenderPassDescriptor! } }
    
    init() {
    }
    
    func setup() {
        pipeline.setupColor(formats: [Render.shared.view.colorPixelFormat])
        pipeline.createState("\(self.id)", screenShaderName: "fs_display")
    }
        
    func update(context: RenderContext) {
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
        context.addCommand(to: id, priority: 99) { encoder in
            self.pipeline.bind(encoder: encoder)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 3)
        }
    }
    
    func globalBind(to encoder: any MTLRenderCommandEncoder) {
    }
    
}
