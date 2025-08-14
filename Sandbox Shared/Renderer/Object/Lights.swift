//
//  Lights.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/08/10.
//

import Metal
import MetalKit
import simd

enum LightType: Int {
    case directional
    case point
    case spot
    case area
}

class Lights {
    public private(set) var dirLights: [DirLightLayout] = []
    public private(set) var pointLights: [PointLightLayout] = []
    public private(set) var spotLights: [SpotLightLayout] = []

    private var info: Buffer
    private var dirBuffer: Buffer
    private var pointBuffer: Buffer
    private var spotBuffer: Buffer

    private let lightInfoSize  = MemoryLayout<LightInfoLayout>.stride
    private let dirLightSize   = MemoryLayout<DirLightLayout>.stride   * 8
    private let pointLightSize = MemoryLayout<PointLightLayout>.stride * 128
    private let spotLightSize  = MemoryLayout<SpotLightLayout>.stride  * 64

    public init() {
        info        = Buffer(constName: "LightInfo", constSize: lightInfoSize)
        dirBuffer   = Buffer(bufName: "DirectionalLightBuffer", bufSize: dirLightSize, options: [.storageModeShared])
        pointBuffer = Buffer(bufName: "PointLightBuffer", bufSize: pointLightSize, options: [.storageModeShared])
        spotBuffer  = Buffer(bufName: "SpotLightBuffer" , bufSize: spotLightSize, options: [.storageModeShared])
    }

    public func clear() {
        dirLights.removeAll(keepingCapacity: true)
        pointLights.removeAll(keepingCapacity: true)
        spotLights.removeAll(keepingCapacity: true)
    }

    public func update() {
        guard let dataPtr = info.getPointer() else { return }
        let data = dataPtr.bindMemory(to: LightInfoLayout.self, capacity: 1)
        data[0].dirLightCount   = uint(dirLights.count);
        data[0].pointLightCount = uint(pointLights.count);
        data[0].spotLightCount  = uint(spotLights.count);
        data[0].areaLightCount  = 0;
        
        for i in 0..<dirLights.count  {
            dirBuffer.get()?.contents().advanced(by: i * MemoryLayout<DirLightLayout>.stride).copyMemory(from: &dirLights[i], byteCount: MemoryLayout<DirLightLayout>.stride)
        }
        for i in 0..<pointLights.count  {
            pointBuffer.get()?.contents().advanced(by: i * MemoryLayout<PointLightLayout>.stride).copyMemory(from: &pointLights[i], byteCount: MemoryLayout<PointLightLayout>.stride)
        }
        for i in 0..<spotLights.count  {
            spotBuffer.get()?.contents().advanced(by: i * MemoryLayout<SpotLightLayout>.stride).copyMemory(from: &spotLights[i], byteCount: MemoryLayout<SpotLightLayout>.stride)
        }
    }

    public func globalBind(to encoder: MTLRenderCommandEncoder) {
        encoder.pushDebugGroup("GlobalBind: LightBuffer")
        encoder.setFragmentBuffer(info.get()       , offset: info.getOffset()       , index: ConstIdx.lightsInfo.rawValue)
        encoder.setFragmentBuffer(dirBuffer.get()  , offset: dirBuffer.getOffset()  , index: BuffIdx.dirLights.rawValue)
        encoder.setFragmentBuffer(pointBuffer.get(), offset: pointBuffer.getOffset(), index: BuffIdx.pointLights.rawValue)
        encoder.setFragmentBuffer(spotBuffer.get() , offset: spotBuffer.getOffset() , index: BuffIdx.spotLights.rawValue)
        encoder.popDebugGroup()
    }
    
    public func add(dirLight   light: DirLightLayout)   { dirLights.append(light)   }
    public func add(pointlight light: PointLightLayout) { pointLights.append(light) }
    public func add(spotLight  light: SpotLightLayout)  { spotLights.append(light)  }

    public static func makeDirLight(dir      : Float3 = Float3(0, -1, 0),
                                    color    : Float3 = Float3(1, 1, 1),
                                    intensity: Float  = 1.0,
                                    castShadows: Bool = false) -> DirLightLayout {
        return DirLightLayout(direction  : dir,
                              intensity  : intensity,
                              color      : color,
                              castShadows: bool(castShadows))
    }
    
    public static func makePointLight(pos      : Float3 = Float3(0, 1, 0),
                                      color    : Float3 = Float3(1, 1, 1),
                                      intensity: Float  = 1.0,
                                      range    : Float  = 10.0,
                                      falloff  : Float  = 2.0,
                                      castShadows: Bool = false) -> PointLightLayout {
        return PointLightLayout(position    : pos,
                                intensity   : intensity,
                                color       : color,
                                castShadows : bool(castShadows),
                                range       : range,
                                falloff     : falloff,
                                _pad        : 0)
    }
    
    public static func makeSpotLight(pos      : Float3 = Float3(0, 1, 0),
                                     dir      : Float3 = Float3(0, -1, 0),
                                     color    : Float3 = Float3(1, 1, 1),
                                     intensity: Float  = 1.0,
                                     range    : Float  = 10.0,
                                     falloff  : Float  = 2.0,
                                     innerConeAngle: Float = 20.0,
                                     outerConeAngle: Float = 30.0,
                                     castShadows: Bool = false) -> SpotLightLayout {
        return SpotLightLayout(position     : pos,
                               intensity    : intensity,
                               color        : color,
                               castShadows  : bool(castShadows),
                               direction    : dir,
                               range        : range,
                               falloff      : falloff,
                               innerConeCos : degrees(innerConeAngle),
                               outerConeCos : degrees(outerConeAngle),
                               _pad         : 0)
    }
}
