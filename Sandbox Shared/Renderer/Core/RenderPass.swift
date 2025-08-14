//
//  RenderPass.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/11.
//

import Metal
import MetalKit
import simd

protocol RenderPass {
    var id: RenderPassId { get }
    var descriptor: MTLRenderPassDescriptor { get }
    
    func setup()
    func update(context: RenderContext)
    func draw(context: RenderContext)
    func globalBind(to encoder: MTLRenderCommandEncoder)
}
