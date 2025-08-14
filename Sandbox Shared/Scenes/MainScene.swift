//
//  MainScene.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/21.
//

import Metal
import MetalKit
import simd

class MainScene: Scene {
    private let label: String = "TestScene"
    
    private var pipeline: Pipeline
    private var box: Mesh
    private var sphere: Mesh
    
    private var rotation: Float = 0;
    
    override init() {
        pipeline = Pipeline()
        sphere = Mesh(material: Material("PavingStones122", types: [.Color, .Normal, .RMAD]))
        box = Mesh(material: Material("Metal056B", types: [.Color, .Normal, .RMAD]))
    }
    
    override func setup() {
        guard let gbufferPass = renderer.renderPassDict[.GBufferPass] as? GBufferPass else { return }
        
        sphere.setup(layouts: [.pos, .tbn, .uv0])
        sphere.createSphere(segments: 512)
        box.setup(layouts: [.pos, .tbn, .uv0])
        box.createBox()
        
        pipeline = Pipeline(pipeline: gbufferPass.getPipeline())
        pipeline.setupVertDesc(box.getVertDesc())
        pipeline.setupShader(Shader(vsName: "vs_gbuffer", fsName: "fs_gbuffer"))
        pipeline.createState(label)
        
        renderer.lights.add(pointlight: Lights.makePointLight())
    }
    
    override func update(context: RenderContext) {
        sphere.getMaterial().update()
        box.getMaterial().update()
        
//        rotation -= 0.01;
    }
    
    override func draw(context: RenderContext) {
        context.addCommand(to: .GBufferPass, priority: 0) { encoder in
            self.pipeline.bind(encoder: encoder)
            
            self.box.update(position: SIMD3<Float>(-2, 0, 0),
                            rotation: SIMD3<Float>(self.rotation, self.rotation, 0))
            self.box.draw(encoder: encoder)
            
            self.sphere.draw(encoder: encoder)
        }
    }
}
