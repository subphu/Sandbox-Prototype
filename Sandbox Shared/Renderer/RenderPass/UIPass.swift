//
//  UIPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/21.
//

import Metal
import MetalKit
import simd

class UIPass: RenderPass {
    private(set) var id: RenderPassId = .UIPass
    private(set) var descriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
     
    private let mainPipeline: Pipeline = Pipeline()
    private var axisPipeline: Pipeline = Pipeline()
    private var gridPipeline: Pipeline = Pipeline()
    
    init() {
    }
    
    func setup() {
        mainPipeline.setupDepth()
        mainPipeline.setupBlending(for: [0])
        mainPipeline.setupColor(formats: [Render.shared.frameInfo.format])
        
        axisPipeline = Pipeline(pipeline: mainPipeline)
        gridPipeline = Pipeline(pipeline: mainPipeline)
        
        axisPipeline.createState("Axis", vsName: "vs_axis", fsName: "fs_line")
        gridPipeline.createState("Grid", vsName: "vs_grid", fsName: "fs_line")
    }
    
    func update(context: RenderContext) {
        descriptor.depthAttachment = Render.shared.frameInfo.depthAttachment
        descriptor.colorAttachments[0] = Render.shared.frameInfo.colorAttachment
        context.addRenderpassDesc(to: id, descriptor: descriptor)
    }
    
    func draw(context: RenderContext) {
        context.addCommand(to: id, priority: 0) { encoder in
            self.gridPipeline.bind(encoder: encoder)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 3, instanceCount: 100 * 4)
            
            self.axisPipeline.bind(encoder: encoder)
            encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: 3, instanceCount: 2)
        }
    }
    
    func globalBind(to encoder: any MTLRenderCommandEncoder) {
        
    }
    
    func getPipeline() -> Pipeline { return mainPipeline }
    
}
