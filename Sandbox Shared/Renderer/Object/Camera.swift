//
//  Test.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/14.
//

import Metal
import MetalKit
import simd

class Camera {
    let target   = vector_float3(0, 0, 0)
    var position = vector_float3(1, 1, 5)
    var right    = vector_float3(1, 0, 0)
    var up       = vector_float3(0, 1, 0)
    var front    = vector_float3(0, 0, 1)
    var worldUp  = vector_float3(0, 1, 0)
    
    var zNear: Float = 0.01
    var zFar : Float = 1000.0
    var speed: Float = 0.10
    var sensitivity: Float = 0.07
    var viewAngle: Float = 60.0
    
//    var position: simd_float3 = [0, 0, -5.0]
//    var target: simd_float3 = .zero
//    var up: simd_float3 = [0, 1, 0]
//
//    var fov: Float = 60.0  // degrees
//    var aspect: Float = 1.0
//    var nearZ: Float = 0.01
//    var farZ: Float = 1000.0

    init() {
        move(direction: vector_float3(0, 0, 0))
    }
    
    func look(at pos: vector_float3) {
        front = normalize(pos - position)
        right = normalize(cross(front, worldUp))
        up    = normalize(cross(right, front))
    }
    
    func move(direction: vector_float3) {
        let velocity = direction * speed
        var distance = getDistance()
        distance = distance > 100.0 ? 100.0 : distance
        let step = distance * 0.04
        
        position += front * velocity.z * step
        position += right * velocity.x * step
        position += up    * velocity.y * step
        
        look(at: target)
        let newDistance = getDistance()
        if (direction.z == 0 || newDistance > 100) {
            position = position * distance / newDistance
        }
    }
    
    func getDistance() -> Float {
        return distance(position, target)
    }
    
    func getViewMatrix() -> float4x4 {
        let p = position, r = right, u = up, f = -front
        let t = vector_float3(-dot(r, p), -dot(u, p), -dot(f, p))
        return float4x4.init(columns:(vector_float4(r.x, u.x, f.x, 0),
                                      vector_float4(r.y, u.y, f.y, 0),
                                      vector_float4(r.z, u.z, f.z, 0),
                                      vector_float4(t.x, t.y, t.z, 1)))
    }
    
    func getProjectionMatrix() -> float4x4 {
        let aspectRatio = Render.shared.frameInfo.aspectRatio
        let fovy = degrees(viewAngle)
        let ys = 1 / tanf(fovy * 0.5)
        let xs = ys / aspectRatio
        let zs = zNear / (zFar - zNear)
        let zw = zFar * zs
        return float4x4.init(columns:(vector_float4(xs,  0,  0,  0),
                                      vector_float4( 0, ys,  0,  0),
                                      vector_float4( 0,  0, zs, -1),
                                      vector_float4( 0,  0, zw,  0)))
    }
    
    var viewMatrix: float4x4 {
        return getViewMatrix()
    }
    
    var projMatrix: float4x4 {
        return getProjectionMatrix()
    }
    
    var viewProjMatrix: float4x4 {
        return simd_mul(projMatrix, viewMatrix)
    }
    
    func updateMatrix() {
        
    }
    
//    var viewMatrix: float4x4 {
//        return float4x4(lookAt: position, target, up)
//    }
//    
//    var projectionMatrix: float4x4 {
//        return float4x4(perspectiveFov: degrees(fov), aspect, nearZ, farZ)
//    }
//
//
//    func look(at target: simd_float3) {
//        self.target = target
//    }
//    
//    func move(delta: simd_float3) {
//        position += delta
//        target += delta
//    }
//    
//    func updateAspectRatio(from size: CGSize) {
//        aspect = Float(size.width / size.height)
//    }
}
