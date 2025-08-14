//
//  Mesh.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/15.
//

import Metal
import MetalKit
import simd

private let VertAttrName: [VertAttr: String] = [
    .position   : MDLVertexAttributePosition,
    .normal     : MDLVertexAttributeNormal,
    .tangent    : MDLVertexAttributeTangent,
    .texcoord0  : MDLVertexAttributeTextureCoordinate
]

private let VertAttrDesc: [VertAttr: MTLVertexAttributeDescriptor] = [
    .position   : MTLVertexAttributeDescriptor(format: .float3, offset:  0, buffIdx: .pos),
    .normal     : MTLVertexAttributeDescriptor(format: .float3, offset:  0, buffIdx: .tbn),
    .tangent    : MTLVertexAttributeDescriptor(format: .float4, offset: 12, buffIdx: .tbn),
    .texcoord0  : MTLVertexAttributeDescriptor(format: .float2, offset:  0, buffIdx: .uv0)
]

private let VertLayoutDesc: [VertIdx: MTLVertexBufferLayoutDescriptor] = [
    .pos : MTLVertexBufferLayoutDescriptor(stride: 12),
    .tbn : MTLVertexBufferLayoutDescriptor(stride: 28),
    .uv0 : MTLVertexBufferLayoutDescriptor(stride:  8)
]

private let VertLayoutAttr: [VertIdx: [VertAttr]] = [
    .pos : [.position],
    .tbn : [.normal, .tangent],
    .uv0 : [.texcoord0]
]

class Mesh {
    private var mtlVertDesc: MTLVertexDescriptor!
    private var mdlVertDesc: MDLVertexDescriptor!
    private var mdlMesh: MDLMesh!
    private var mtkMesh: MTKMesh!
    
    private var layouts: [VertIdx] = []
    private var attributes: [VertAttr] = []
    
    private var position: SIMD3<Float> = .zero
    private var rotation: SIMD3<Float> = .zero
    private var scale: SIMD3<Float> = .one
    private var modelData = ModelLayout(modelMatrix: matrix_identity_float4x4, normalMatrix: matrix_identity_float4x4)
    private let modelSize = roundUp(MemoryLayout<ModelLayout>.size)
    
    private var material: Material = Material()
    
    init() {
    }
    
    convenience init(material: Material) {
        self.init()
        self.material = material
    }
    
    func setup(layouts: [VertIdx]) {
        self.mtlVertDesc = MTLVertexDescriptor()
        self.layouts = layouts
        self.attributes = []
        
        for layout in layouts {
            attributes.append(contentsOf: VertLayoutAttr[layout]!)
            mtlVertDesc.layouts[layout.rawValue] = VertLayoutDesc[layout]
        }
        
        for attr in attributes {
            mtlVertDesc.attributes[attr.rawValue] = VertAttrDesc[attr];
        }
        
        mdlVertDesc = MTKModelIOVertexDescriptorFromMetal(mtlVertDesc)
        guard let mdlVertAttr = mdlVertDesc.attributes as? [MDLVertexAttribute] else { return }
        
        for attr in attributes {
            mdlVertAttr[attr.rawValue].name = VertAttrName[attr]!;
        }
    }
    
    func createBox() {
        let mdlMesh = MDLMesh.newBox(withDimensions: SIMD3<Float>(1, 1, 1),
                                     segments: SIMD3<UInt32>(1, 1, 1),
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: Render.shared.meshAllocator)
        create(mdlMesh: mdlMesh)
    }
    
    func createSphere(segments: Int = 32) {
        let mdlMesh = MDLMesh.newEllipsoid(withRadii: SIMD3<Float>(0.5, 0.5, 0.5),
                                           radialSegments: segments,
                                           verticalSegments: segments,
                                           geometryType: .triangles,
                                           inwardNormals: false,
                                           hemisphere: false,
                                           allocator: Render.shared.meshAllocator)
        create(mdlMesh: mdlMesh)
    }
    
    func createIcosahedron() {
        let mdlMesh = MDLMesh.newIcosahedron(withRadius: 1,
                                             inwardNormals: false,
                                             geometryType: .triangles,
                                             allocator: Render.shared.meshAllocator)
        let subdivMesh = MDLMesh.newSubdividedMesh(mdlMesh, submeshIndex: 0, subdivisionLevels: 3)!
        create(mdlMesh: subdivMesh)
    }
    
    func create(mdlMesh: MDLMesh) {
        mdlMesh.addOrthTanBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                normalAttributeNamed: MDLVertexAttributeNormal,
                                tangentAttributeNamed: MDLVertexAttributeTangent)
        mdlMesh.vertexDescriptor = mdlVertDesc
        mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Render.shared.device)
    }
    
    func update(position: SIMD3<Float> = .zero, rotation: SIMD3<Float> = .zero, scale: SIMD3<Float> = .one) {
        self.position = position
        self.rotation = rotation
        self.scale    = scale
        self.modelData.modelMatrix = float4x4(translation: position, rotation: rotation, scale: scale)
        self.modelData.normalMatrix = simd_inverse(simd_transpose(self.modelData.modelMatrix))
    }
    
    func draw(encoder: MTLRenderCommandEncoder) {
        material.bind(encoder: encoder)
        encoder.setVertexBytes(&modelData, length: modelSize, index: ConstIdx.model.rawValue)
        for layout in layouts {
            let vb = mtkMesh.vertexBuffers[layout.rawValue]
            encoder.setVertexBuffer(vb.buffer, offset: vb.offset, index: layout.rawValue)
        }
        for submesh in mtkMesh.submeshes {
            encoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                          indexCount: submesh.indexCount,
                                          indexType: submesh.indexType,
                                          indexBuffer: submesh.indexBuffer.buffer,
                                          indexBufferOffset: submesh.indexBuffer.offset)
        }
    }
    
    func getVertDesc() -> MTLVertexDescriptor { return mtlVertDesc }
    func getMaterial() -> Material            { return material }
}
