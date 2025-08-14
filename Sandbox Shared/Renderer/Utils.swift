//
//  Common.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/02/24.
//


import Metal
import MetalKit
import simd
import SwiftUI

public typealias Float2 = simd_float2
public typealias Float3 = simd_float3
public typealias Float4 = simd_float4

enum RendererError: Error {
    case badVertexDescriptor
}

enum StencilValue: UInt32 {
    case Empty
    case GBuffer
    case Light
}

let FloatSize: Int = MemoryLayout<Float>.size

func roundUp(_ size: Int, pow shift: Int = 8) -> Int {
    let alignment = 1 << shift
    return (size + (alignment - 1)) & -alignment
}

func degrees(_ degrees: Float) -> Float {
    return  degrees * .pi / 180
}

func radians(_ radians: Float) -> Float {
    return  radians * 180 / .pi
}

func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func bool(_ value: Bool) -> uint {
    return value ? 1 : 0
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> float4x4 {
    return float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

extension float4x4 {
    init(translation t: SIMD3<Float>, rotation r: SIMD3<Float>, scale s: SIMD3<Float>) {
        let sm = float4x4(scale: s)
        let rm = float4x4(rotation: r)
        let tm = float4x4(translation: t)
        self = tm * rm * sm
    }
    
    init(scale s: SIMD3<Float>) {
        self = float4x4(diagonal: SIMD4<Float>(s, 1.0))
    }
    
    init(translation t: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(t, 1.0)
    }
    
    init(rotation r: SIMD3<Float>) {
        let rx = float4x4.init(rotationX: r.x)
        let ry = float4x4.init(rotationY: r.y)
        let rz = float4x4.init(rotationZ: r.z)
        self = rz * ry * rx
    }

    init(rotationX angle: Float) {
        self = matrix_identity_float4x4
        let c = cos(angle)
        let s = sin(angle)
        columns.1.y = c
        columns.1.z = s
        columns.2.y = -s
        columns.2.z = c
    }

    init(rotationY angle: Float) {
        self = matrix_identity_float4x4
        let c = cos(angle)
        let s = sin(angle)
        columns.0.x = c
        columns.0.z = -s
        columns.2.x = s
        columns.2.z = c
    }

    init(rotationZ angle: Float) {
        self = matrix_identity_float4x4
        let c = cos(angle)
        let s = sin(angle)
        columns.0.x = c
        columns.0.y = s
        columns.1.x = -s
        columns.1.y = c
    }
    
    init(lookAt eye: simd_float3, _ center: simd_float3, _ up: simd_float3) {
        let f = simd_normalize(center - eye)
        let s = simd_normalize(simd_cross(f, up))
        let u = simd_cross(s, f)

        self.init(
            simd_float4(s.x, u.x, -f.x, 0),
            simd_float4(s.y, u.y, -f.y, 0),
            simd_float4(s.z, u.z, -f.z, 0),
            simd_float4(-simd_dot(s, eye), -simd_dot(u, eye), simd_dot(f, eye), 1)
        )
    }
    
    init(perspectiveFov fovY: Float, _ aspect: Float, _ nearZ: Float, _ farZ: Float) {
        let yScale = 1 / tan(fovY * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = farZ / zRange
        let wz = -nearZ * zScale
        
        self.init(
            simd_float4(xScale, 0, 0, 0),
            simd_float4(0, yScale, 0, 0),
            simd_float4(0, 0, zScale, 1),
            simd_float4(0, 0, wz, 0)
        )
    }
}

extension MTLVertexDescriptor {
    func setAttr(_ attr: VertAttr, format: MTLVertexFormat, offset: Int, buffIdx: VertIdx) {
        attributes[attr.rawValue].format = format
        attributes[attr.rawValue].offset = offset
        attributes[attr.rawValue].bufferIndex = buffIdx.rawValue
    }
    
    func setLayout(_ idx: VertIdx, stride: Int) {
        layouts[idx.rawValue].stride = stride
        layouts[idx.rawValue].stepRate = 1
        layouts[idx.rawValue].stepFunction = .perVertex
    }
    
    func setupPositionAttr() {
        setAttr(.position , format: .float3, offset:  0, buffIdx: .pos)
        setLayout(.pos, stride: 12)
    }
    
    func setupGenericsAttr() {
        setAttr(.normal , format: .float3, offset:  0, buffIdx: .tbn)
        setAttr(.tangent, format: .float4, offset: 12, buffIdx: .tbn)
        setLayout(.tbn, stride: 28)
    }
    
    func setupExtraAttr() {
        setAttr(.texcoord0, format: .float2, offset:  0, buffIdx: .uv0)
        setLayout(.uv0, stride: 8)
    }
}

extension MTLVertexAttributeDescriptor {
    convenience init(format: MTLVertexFormat, offset: Int, buffIdx: VertIdx) {
        self.init()
        self.format = format
        self.offset = offset
        self.bufferIndex = buffIdx.rawValue
    }
}

extension MTLVertexBufferLayoutDescriptor {
    convenience init(stride: Int) {
        self.init()
        self.stride = stride
        self.stepRate = 1
        self.stepFunction = .perVertex
    }
}


