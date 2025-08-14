//
//  FrameInfo.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/11.
//

import Metal
import MetalKit
import simd


class FrameInfo {
    static let frameMax = 3
    
    private var frameColor: Texture
    private var frameDepthStencil: Texture
    private var InfoCB: Buffer
    
    private var frameCtr = 0
    private var ratio: Float = 1.0
    private var resolution: CGSize = .zero
    private let startTime = Date().timeIntervalSince1970
    
    private var renderPassDesc: MTLRenderPassDescriptor
    private var prevViewProjMat: float4x4 = matrix_identity_float4x4
    
    var colorAttachment  : MTLRenderPassColorAttachmentDescriptor   { get { return renderPassDesc.colorAttachments[0] } }
    var depthAttachment  : MTLRenderPassDepthAttachmentDescriptor   { get { return renderPassDesc.depthAttachment } }
    var stencilAttachment: MTLRenderPassStencilAttachmentDescriptor { get { return renderPassDesc.stencilAttachment } }
    
    
    var format: MTLPixelFormat { get { return frameColor.getFormat() } }
    var width : Int            { get { return Int(frameColor.getResolution().width) } }
    var height: Int            { get { return Int(frameColor.getResolution().height) } }

    var texture    : Texture   { get { return frameColor } }
    var aspectRatio: Float     { get { return ratio } }
    var frameIdx   : Int       { get { return frameCtr % FrameInfo.frameMax } }

    init(resolution: CGSize) {
        self.resolution = resolution
        self.ratio = Float(resolution.width / resolution.height)
        
        self.frameColor = Texture(rtName: "FrameColor", rtSize: resolution, format: .rgba16Float)
        self.frameDepthStencil = Texture(rtName: "FrameDepthStencil", rtSize: resolution, format: .depth32Float_stencil8)
        self.InfoCB = Buffer(constName: "FrameInfoCB", constSize: MemoryLayout<FrameInfoLayout>.size, perFrame: true)
        
        self.renderPassDesc = MTLRenderPassDescriptor()
        self.renderPassDesc.colorAttachments[0].texture = frameColor.get()
        self.renderPassDesc.colorAttachments[0].clearColor = MTLClearColorMake(0.1725, 0.1725, 0.1804, 1.0)
        self.renderPassDesc.colorAttachments[0].loadAction = .load
        self.renderPassDesc.colorAttachments[0].storeAction = .store
        
        self.renderPassDesc.depthAttachment.texture = frameDepthStencil.get()
        self.renderPassDesc.depthAttachment.clearDepth = 0.0
        self.renderPassDesc.depthAttachment.loadAction = .load
        self.renderPassDesc.depthAttachment.storeAction = .store
        
        self.renderPassDesc.stencilAttachment.texture = frameDepthStencil.get()
        self.renderPassDesc.stencilAttachment.clearStencil = 0
        self.renderPassDesc.stencilAttachment.loadAction = .load
        self.renderPassDesc.stencilAttachment.storeAction = .store
    }
    
    func prepareFrame() {
        frameCtr += 1;
        
        guard let dataPtr = InfoCB.getPointer() else { return }
        let data = dataPtr.bindMemory(to: FrameInfoLayout.self, capacity: 1)
        
        let curTime = Date().timeIntervalSince1970 - startTime
        data[0].timeDelta = Float(curTime) - data[0].timeSecond
        data[0].timeSecond = Float(curTime)
        data[0].resolution = SIMD2(x: Float(resolution.width), y: Float(resolution.height))
        data[0].frameCtr = uint(frameCtr);
        
        data[0].projMatrix    = Render.shared.camera.projMatrix
        data[0].viewMatrix    = Render.shared.camera.viewMatrix
        data[0].invViewMatrix = Render.shared.camera.viewMatrix.inverse
        data[0].viewProjMatrix      = Render.shared.camera.viewProjMatrix
        data[0].invViewProjMatrix   = Render.shared.camera.viewProjMatrix.inverse
        data[0].prevViewProjMatrix  = prevViewProjMat
        
        data[0].cameraPos  = Render.shared.camera.position
        data[0].cameraNear = Render.shared.camera.zNear
        data[0].cameraFar  = Render.shared.camera.zFar
        
        prevViewProjMat = data[0].viewProjMatrix
    }
    
    func globalBind(to encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup("GlobalBind: FrameInfo")
        encoder.setVertexBuffer(InfoCB.get(), offset: InfoCB.getOffset(), index: ConstIdx.frameInfo.rawValue)
        encoder.setFragmentBuffer(InfoCB.get(), offset: InfoCB.getOffset(), index: ConstIdx.frameInfo.rawValue)
        encoder.setFragmentTexture(frameColor.get(), index: TexIdx.displayColor.rawValue)
        encoder.setFragmentTexture(frameDepthStencil.get(), index: TexIdx.depth.rawValue)
        encoder.popDebugGroup()
    }
    
    func setResolution(_ resolution: CGSize) {
        self.resolution = resolution
        self.ratio = Float(resolution.width / resolution.height)
        self.frameColor.resize(resolution)
        self.frameDepthStencil.resize(resolution)
        self.renderPassDesc.colorAttachments[0].texture = frameColor.get()
        self.renderPassDesc.depthAttachment.texture = frameDepthStencil.get()
        self.renderPassDesc.stencilAttachment.texture = frameDepthStencil.get()
    }
    
}
