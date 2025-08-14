//
//  Material.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/29.
//

#include <metal_stdlib>
#include <simd/simd.h>

#import "../ShaderTypes.h"
#import "Utils.metal"
#import "Data.metal"

using namespace metal;

struct Material {
    float3 color  = float3(1, 1, 1);
    float3 normal = float3(0, 1, 0);
    
    float  roughness  = 1;
    float  roughness2 = 1;
    float  metallic   = 1;
    float  ao         = 1;
    float  alpha      = 1;

    float  specular   = 0.04;
    float  ior        = 1;
    float  emission   = 0;
    
    float3 coatNormal     = float3(0, 1, 0);
    float  coatIOR        = 1.0;
    float  coatThickness  = 0.0;
    float  coatRoughness  = 0.01;
    float  coatRoughness2 = 0.0001;
    
    float  anisotropic         = 0;
    float  anisotropicRotation = 0;
    
    float  sheen     = 0;
    float  sheenTint = 0;
    
    float  transmission          = 0;
    float  transmissionRoughness = 0;
    
    float  subsurface       = 0;
    float  subsurfaceRadius = 0;
    float3 subsurfaceColor  = 0;
    
    float3 F0 = float3(0, 0, 0);
    float3 encodedNorm = float3(0, 1, 0);
};

inline float2 encodeOctahedron(float3 n) {
    float2 no = n.xy / (fabs(n.x) + fabs(n.y) + fabs(n.z));
    if (n.z < 0.0) {
        float2 sign;
        sign.x = n.x >= 0.0 ? 1.0 : -1.0;
        sign.y = n.y >= 0.0 ? 1.0 : -1.0;
        no = (1.0 - fabs(no.yx)) * sign.xy;
    }
    return no;
}

inline float3 decodeOctahedron(float2 no) {
    float3 n = float3(no.x, no.y, 1.0 - fabs(no.x) - fabs(no.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - fabs(n.yx)) * sign(n.xy);
    }
    return normalize(n);
}

inline uint3 encode2snorm12bit(float2 val) {
    uint2 val12bit  = uint2(saturate(unorm(val)) * MAX12BIT);
    uint2 high8bit  = val12bit.xy >> 4;
    uint2 low4bit   = val12bit.xy & 0x0F;
    uint  packedLow = (low4bit.x << 4) | low4bit.y;
    return uint3(high8bit, packedLow);
}

inline float2 decode2snorm12bit(uint3 val) {
    uint3 val8bit  = val & 0xFF;
    uint2 low4bit  = uint2(val8bit.z >> 4, val8bit.z & 0x0F);
    uint2 val12bit = (val8bit.xy << 4) | low4bit;
    return snorm(float2(val12bit) * RCP12BIT);
}

inline float3 encodeNormal(float3 normal) {
    float2 normOct   = encodeOctahedron(normal);
    uint3  norm12bit = encode2snorm12bit(normOct);
    return float3(norm12bit) * RCP8BIT;
}

inline float3 decodeNormal(float3 encoded) {
    uint3  norm12bit = uint3(encoded * MAX8BIT);
    float2 normOct   = decode2snorm12bit(norm12bit);
    return decodeOctahedron(normOct);
}

static Material processMaterial(Material mt) {
    float3 dielectricF0 = float3(0.04) * mt.specular;
    mt.F0 = mix(dielectricF0, mt.color, mt.metallic);
    
    mt.roughness2     = mt.roughness * mt.roughness;
    mt.coatRoughness2 = mt.coatRoughness * mt.coatRoughness;
    mt.encodedNorm    = encodeNormal(mt.normal);
    
    return mt;
}

static Material makeMaterial(MATERIALS, FragInfo fi) {
    Material mt;
    
    float4 rmad   = rmadTex  .sample(clampSampler, fi.texCoord);
    float3 normal = normalTex.sample(clampSampler, fi.texCoord).xyz;
    float4 color  = colorTex .sample(clampSampler, fi.texCoord);
    
    mt.color      = pow(color.rgb, 2.2);
    mt.normal     = normalize(fi.TBN * snorm(normal));
    mt.ao         = rmad.b;
    mt.metallic   = rmad.g * material.metallic;
    mt.roughness  = rmad.r * material.roughness;
    
    mt.alpha                 = material.alpha;
    mt.specular              = material.specular;
    mt.ior                   = material.ior;
    mt.emission              = material.emission;
    
    mt.coatIOR               = material.coatIOR;
    mt.coatThickness         = material.coatThickness;
    mt.coatRoughness         = material.coatRoughness;
    
    mt.anisotropic           = material.anisotropic;
    mt.anisotropicRotation   = material.anisotropicRotation;
    
    mt.sheen                 = material.sheen;
    mt.sheenTint             = material.sheenTint;
    
    mt.transmission          = material.transmission;
    mt.transmissionRoughness = material.transmission;
    
    mt.subsurface            = material.subsurface;
    mt.subsurfaceRadius      = material.subsurfaceRadius;
    mt.subsurfaceColor       = material.subsurfaceColor;

    return processMaterial(mt);
}

static Material makeMaterial(GBUFFER, float2 texCoord) {
    Material mt;
    
    float4 gb0 = gbuffer0.sample(clampSampler, texCoord);
    float4 gb1 = gbuffer1.sample(clampSampler, texCoord);
    float4 gb2 = gbuffer2.sample(clampSampler, texCoord);
    
    mt.color     = gb0.rgb;
    mt.roughness = gb0.a;
    mt.normal    = decodeNormal(gb1.rgb);
    mt.metallic  = gb1.a;
    mt.specular  = gb2.r;
    mt.ao        = gb2.g;
    
    return processMaterial(mt);
}

static GBuffers makeGBuffers(Material mt) {
    GBuffers gb;
    gb.tex0 = float4(mt.color, mt.roughness);
    gb.tex1 = float4(mt.encodedNorm, mt.metallic);
    gb.tex2 = float4(mt.specular, mt.ao, 1, 1);
    return gb;
}
