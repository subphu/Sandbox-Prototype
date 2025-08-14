//
//  Material.swift
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/27.
//

import Metal
import MetalKit
import simd

class Material {
    private var name: String = ""
    private var properties: [MaterialProperty: Float] = [:]
    private var textures: [TextureType: Texture] = [:]
    
    private var materialCB: Buffer
    
    init() {
        properties = [
            .baseColorR : 1.0,
            .baseColorG : 1.0,
            .baseColorB : 1.0,
            .alpha      : 1.0,
            
            .roughness  : 1.0,
            .metallic   : 1.0,
            .specular   : 0.04,
            .ior        : 1.45,
            
            .emission      : 0.0,
            .coatIOR       : 1.0,
            .coatThickness : 0.0,
            .coatRoughness : 0.0,

            .anisotropic        : 0.0,
            .anisotropicRotation: 0.0,
            .sheen      : 0.0,
            .sheenTint  : 0.0,

            .transmission           : 0.0,
            .transmissionRoughness  : 0.0,
            .subsurface      : 0.0,
            .subsurfaceRadius: 0.0,

            .subsurfaceColorR: 0.0,
            .subsurfaceColorG: 0.0,
            .subsurfaceColorB: 0.0,
        ]
        materialCB = Buffer(constName: "MaterialCB", constSize: FloatSize * MaterialProperty.total.rawValue)
    }

    convenience init(_ name: String, types: [TextureType]) {
        self.init()
        self.name = name
        set(textures: types)
    }
    
    func set(textures types: [TextureType]) {
        for type in types {
            textures[type] = Texture("\(name)_\(type)")
        }
    }
    
    func set(_ type: MaterialProperty, value: Float) {
        properties[type] = value
    }
     
    func update(properties updatedProperties: [MaterialProperty: Float] = [:]) {
        updatedProperties.forEach { set($0.key, value: $0.value) }
        
        guard let dataPtr = materialCB.getPointer() else { return }
        let data = dataPtr.bindMemory(to: MaterialLayout.self, capacity: 1)
        data[0].baseColor = SIMD3(x: properties[.baseColorR]!,
                                  y: properties[.baseColorG]!,
                                  z: properties[.baseColorB]!)
        data[0].alpha     = properties[.alpha]!
        
        data[0].roughness = properties[.roughness]!
        data[0].metallic  = properties[.metallic]!
        data[0].specular  = properties[.specular]!
        data[0].ior       = properties[.ior]!
        
        data[0].emission      = properties[.emission]!
        data[0].coatIOR       = properties[.coatIOR]!
        data[0].coatThickness = properties[.coatThickness]!
        data[0].coatRoughness = properties[.coatRoughness]!

        data[0].anisotropic         = properties[.anisotropic]!
        data[0].anisotropicRotation = properties[.anisotropicRotation]!
        data[0].sheen               = properties[.sheen]!
        data[0].sheenTint           = properties[.sheenTint]!

        data[0].transmission          = properties[.transmission]!
        data[0].transmissionRoughness = properties[.transmissionRoughness]!
        data[0].subsurface            = properties[.subsurface]!
        data[0].subsurfaceRadius      = properties[.subsurfaceRadius]!

        data[0].subsurfaceColor = SIMD3(x: properties[.subsurfaceColorR]!,
                                        y: properties[.subsurfaceColorG]!,
                                        z: properties[.subsurfaceColorB]!)
    }
    
    func bind(encoder: MTLRenderCommandEncoder) {
        encoder.setVertexTexture(textures[.RMAD]!.get(), index: TexIdx.RMAD.rawValue)
        encoder.setFragmentBuffer(materialCB.get(), offset: 0, index: ConstIdx.material.rawValue)
        for (key, tex) in textures {
            encoder.setFragmentTexture(tex.get(), index: TexIdx.color.rawValue + key.rawValue)
        }
    }
}

enum TextureType: Int {
    case Color
    case Normal
    case RMAD
    case Displacement
    case Tangent
    case CoatNormal
    case Emissive
}

enum MaterialProperty: Int {
    // Core properties
    case baseColorR
    case baseColorG
    case baseColorB
    case alpha
    
    case roughness
    case metallic
    case specular
    case ior
    
    // Emission
    case emission

    // Clearcoat layer
    case coatIOR
    case coatThickness
    case coatRoughness

    // Anisotropy
    case anisotropic
    case anisotropicRotation

    // Sheen (for fabric)
    case sheen
    case sheenTint

    // Transmission
    case transmission
    case transmissionRoughness

    // Subsurface scattering
    case subsurface
    case subsurfaceRadius
    case subsurfaceColorR
    case subsurfaceColorG
    case subsurfaceColorB
    
    case total
}



