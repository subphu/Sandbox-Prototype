//
//  Pipeline.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/13.
//

import Metal
import MetalKit
import simd

class Pipeline {
    private var pipelineDesc: MTLRenderPipelineDescriptor
    private var depthStencilDesc: MTLDepthStencilDescriptor?
    
    private var pipelineState: MTLRenderPipelineState?
    private var depthStencilState: MTLDepthStencilState?

    init() {
        self.pipelineDesc = MTLRenderPipelineDescriptor()
        self.pipelineDesc.rasterSampleCount = 1
    }
    
    init(pipeline: Pipeline) {
        self.pipelineDesc = pipeline.getDesc()
        self.depthStencilDesc = pipeline.getDSDesc()
    }
    
    func setupShader(_ shader: Shader) {
        pipelineDesc.vertexFunction = shader.getVS()
        pipelineDesc.fragmentFunction = shader.getFS()
    }
    
    func setupColor(formats: [MTLPixelFormat]) {
        for i in 0..<formats.count {
            pipelineDesc.colorAttachments[i].pixelFormat = formats[i]
        }
    }
    
    func setupDepth(format: MTLPixelFormat = .depth32Float_stencil8) {
        pipelineDesc.depthAttachmentPixelFormat = format
        
        let descriptor = depthStencilDesc ?? MTLDepthStencilDescriptor()
        descriptor.isDepthWriteEnabled = true
        descriptor.depthCompareFunction = .greater
        depthStencilDesc = descriptor
    }
    
    func setupDepthCheck(format: MTLPixelFormat = .depth32Float_stencil8) {
        pipelineDesc.depthAttachmentPixelFormat = format
        
        let descriptor = depthStencilDesc ?? MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .notEqual
        depthStencilDesc = descriptor
    }
    
    func setupStencil(operation: MTLStencilOperation = .replace, writeMask: UInt32 = 0xFF) {
        pipelineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
        let stencilDesc = MTLStencilDescriptor()
        stencilDesc.stencilCompareFunction = .always
        stencilDesc.stencilFailureOperation = .keep
        stencilDesc.depthFailureOperation = .keep
        stencilDesc.depthStencilPassOperation = operation
        stencilDesc.writeMask = writeMask
        stencilDesc.readMask = 0xFF
        
        let descriptor = depthStencilDesc ?? MTLDepthStencilDescriptor()
        descriptor.backFaceStencil = stencilDesc
        descriptor.frontFaceStencil = stencilDesc
        descriptor.isDepthWriteEnabled = true
        depthStencilDesc = descriptor
    }
    
    func setupStencilCheck() {
        pipelineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
        
        let stencilDesc = MTLStencilDescriptor()
        stencilDesc.stencilCompareFunction = .equal
        stencilDesc.readMask = 0xFF
        
        let descriptor = depthStencilDesc ?? MTLDepthStencilDescriptor()
        descriptor.backFaceStencil = stencilDesc
        descriptor.frontFaceStencil = stencilDesc
        depthStencilDesc = descriptor
    }
    
    func setupDepthStencil() {
        setupDepth()
        setupStencil()
        pipelineDesc.depthAttachmentPixelFormat = .depth32Float_stencil8
        pipelineDesc.stencilAttachmentPixelFormat = .depth32Float_stencil8
    }
    
    func setupVertDesc(_ vertDesc: MTLVertexDescriptor) {
        pipelineDesc.vertexDescriptor = vertDesc
    }
    
    func createState(_ label: String, _ setup: (MTLRenderPipelineDescriptor) -> Void) {
        setup(pipelineDesc)
        createState(label)
    }

    func createState(_ label: String, screenShaderName: String) {
        setupShader(Shader(screenShaderName: screenShaderName))
        createState(label)
    }
    
    func createState(_ label: String, vsName: String, fsName: String) {
        setupShader(Shader(vsName: vsName, fsName: fsName))
        createState(label)
    }
    
    func createState(_ label: String? = nil) {
        pipelineDesc.label = "Pipeline: \(label ?? "Unknown")"
        createDSState()
        
        do { pipelineState = try Render.shared.device.makeRenderPipelineState(descriptor: pipelineDesc) }
        catch { print("Error::Unable to compile render pipeline state. Error info: \(error)") }
    }
    
    func createDSState() {
        guard let descriptor = depthStencilDesc else { return }
        depthStencilState = Render.shared.device.makeDepthStencilState(descriptor: descriptor)
    }
        
    func bind(encoder: MTLRenderCommandEncoder) {
        bindState(encoder: encoder)
        bindDSState(encoder: encoder)
    }
    
    func bindState(encoder: MTLRenderCommandEncoder) {
        guard let state = pipelineState else { return }
        encoder.setRenderPipelineState(state)
    }
    
    func bindDSState(encoder: MTLRenderCommandEncoder) {
        guard let state = depthStencilState else { return }
        encoder.setDepthStencilState(state)
    }
    
    func getDesc() -> MTLRenderPipelineDescriptor { return pipelineDesc }
    func getDSDesc() -> MTLDepthStencilDescriptor? { return depthStencilDesc }
    
    func getState() -> MTLRenderPipelineState? { return pipelineState }
    func getDSState() -> MTLDepthStencilState? { return depthStencilState }
    
    
    func setupBlending(for indices: [Int], enabled: Bool = true) {
        for idx in indices {
            guard let attachment = pipelineDesc.colorAttachments[idx] else { return }
            attachment.isBlendingEnabled = enabled
        
            guard enabled else { return }
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add
            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.sourceAlphaBlendFactor = .one
            attachment.destinationAlphaBlendFactor = .zero
        }
    }
    
}


//    init(pipelineDesc: MTLRenderPipelineDescriptor) {
//        self.pipelineDesc = pipelineDesc
//        self.depthStencilDesc = MTLDepthStencilDescriptor()
//    }
//
//    init(depthStencilDesc: MTLDepthStencilDescriptor) {
//        self.pipelineDesc = MTLRenderPipelineDescriptor()
//        self.depthStencilDesc = depthStencilDesc
//    }
//
//    init(pipelineDesc: MTLRenderPipelineDescriptor, depthStencilDesc: MTLDepthStencilDescriptor) {
//        self.pipelineDesc = pipelineDesc
//        self.depthStencilDesc = depthStencilDesc
//    }
//
//    func setup(pipelineDesc: MTLRenderPipelineDescriptor? = nil,
//               depthStencilDesc: MTLDepthStencilDescriptor? = nil) {
//        self.pipelineDesc = pipelineDesc ?? self.pipelineDesc
//        self.depthStencilDesc = depthStencilDesc ?? self.depthStencilDesc
//    }
