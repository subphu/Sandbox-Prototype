//
//  ShaderTypes.h
//  Sandbox Shared
//
//  Created by Subroto Hudiono on 2025/02/23.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t Int32;
#else
#import <Foundation/Foundation.h>
typedef NSInteger Int32;
#endif

#include <simd/simd.h>

typedef NS_ENUM(Int32, SamplerIdx) {
    SamplerIdxDefault = 0
};

typedef NS_ENUM(Int32, TexIdx) {
    TexIdxColor = 0,
    TexIdxNormal,
    TexIdxRMAD,
    TexIdxDisplacement,
    TexIdxTangent,
    TexIdxCoatNormal,
    TexIdxEmissive,
    
    TexIdxDepth = 32,
    TexIdxStencil = 33,
    TexIdxDisplayColor = 36,
    TexIdxGbuffer = 40,
    TexIdxBindless = 64
};

typedef NS_ENUM(Int32, VertAttr) {
    VertAttrPosition  = 0,
    VertAttrNormal,
    VertAttrTangent,
    VertAttrTexcoord0
};

typedef NS_ENUM(Int32, VertIdx) {
    VertIdxPos = 0,
    VertIdxTbn,
    VertIdxUv0
};

typedef NS_ENUM(Int32, ConstIdx) {
    ConstIdxFrameInfo = 4,
    ConstIdxLightsInfo,
    ConstIdxInput,
    
    ConstIdxBytes = 8,
    
    ConstIdxModel = 10,
    ConstIdxMaterial,
    
    ConstIdxCustom = 12
};

typedef NS_ENUM(Int32, BuffIdx) {
    BuffIdxDirLights = 16,
    BuffIdxPointLights,
    BuffIdxSpotLights,
    BuffIdxAreaLights,
    
    BuffIdxDrawArgs = 20,
    BuffIdxMaterials,
    
    BuffIdxParticles = 32,
    BuffIdxCustom = 33
};

struct InputLayout {
    simd_float2 tapPos1;
    simd_float2 tapVel1;
    simd_float2 tapPos2;
    simd_float2 tapVel2;
    uint activeTap;
    simd_float3 gryroData;
};

struct FrameInfoLayout {
    simd_float2 resolution;
    uint frameCtr;
    float framerate;
    float timeSecond;
    float timeDelta;
    matrix_float4x4 projMatrix;
    matrix_float4x4 invProjMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 invViewMatrix;
    matrix_float4x4 viewProjMatrix;
    matrix_float4x4 invViewProjMatrix;
    matrix_float4x4 prevViewProjMatrix;
    simd_float3 cameraPos;
    float cameraNear;
    float cameraFar;
};

struct ModelLayout {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 normalMatrix;
};

struct MaterialLayout {
    simd_float3 baseColor;
    float alpha;
    
    float roughness;
    float metallic;
    float specular;
    float ior;
    
    float emission;
    float coatIOR;
    float coatThickness;
    float coatRoughness;
    
    float anisotropic;
    float anisotropicRotation;
    float sheen;
    float sheenTint;
    
    float transmission;
    float transmissionRoughness;
    float subsurface;
    float subsurfaceRadius;

    simd_float3 subsurfaceColor;
    float padding;
};

struct LightInfoLayout {
    uint dirLightCount;
    uint pointLightCount;
    uint spotLightCount;
    uint areaLightCount;
};

struct DirLightLayout {
    simd_float3 direction;
    float  intensity;
    simd_float3 color;
    uint   castShadows;
};

struct PointLightLayout {
    simd_float3 position;
    float  intensity;
    simd_float3 color;
    uint   castShadows;
    
    float  range;
    float  falloff;
    uint   _pad;
};

struct SpotLightLayout {
    simd_float3 position;
    float  intensity;
    simd_float3 color;
    uint   castShadows;
    
    simd_float3 direction;
    float  range;
    float  falloff;
    float  innerConeCos;
    float  outerConeCos;
    uint   _pad;
};

#endif /* ShaderTypes_h */

