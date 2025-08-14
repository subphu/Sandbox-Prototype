//
//  Utils.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/28.
//

#include <metal_stdlib>
#include <simd/simd.h>

#include "Constants.metal"

using namespace metal;

#define STAGE_IN(_struct) _struct in [[ stage_in ]]

#define VERT_DETAILS \
    uint vertexId   [[ vertex_id   ]], \
    uint instanceId [[ instance_id ]]

#define FRAME_INFO \
    constant FrameInfoLayout& frameInfo  [[ buffer(ConstIdxFrameInfo) ]]

#define GBUFFER_PARAM gbuffer0, gbuffer1, gbuffer2, depthTex, displayColor
#define GBUFFER \
    texture2d<float>  gbuffer0      [[ texture (TexIdxGbuffer+0)    ]], \
    texture2d<float>  gbuffer1      [[ texture (TexIdxGbuffer+1)    ]], \
    texture2d<float>  gbuffer2      [[ texture (TexIdxGbuffer+2)    ]], \
    texture2d<float>  depthTex      [[ texture (TexIdxDepth)        ]], \
    texture2d<float>  displayColor  [[ texture (TexIdxDisplayColor) ]]

#define MATERIALS_PARAM material, colorTex, normalTex, rmadTex
#define MATERIALS \
    constant MaterialLayout& material   [[ buffer  (ConstIdxMaterial) ]], \
    texture2d<float>         colorTex   [[ texture (TexIdxColor)      ]], \
    texture2d<float>         normalTex  [[ texture (TexIdxNormal)     ]], \
    texture2d<float>         rmadTex    [[ texture (TexIdxRMAD)       ]]

#define LIGHTS_PARAM lightInfo, dirLights, pointLights, spotLights
#define LIGHTS \
    constant LightInfoLayout&   lightInfo   [[ buffer (ConstIdxLightsInfo) ]], \
    constant DirLightLayout*    dirLights   [[ buffer (BuffIdxDirLights)   ]], \
    constant PointLightLayout*  pointLights [[ buffer (BuffIdxPointLights) ]], \
    constant SpotLightLayout*   spotLights  [[ buffer (BuffIdxSpotLights)  ]]

#define VERT_INFO_PARAM model, rmadTex
#define VERT_INFO \
    constant ModelLayout& model     [[ buffer(ConstIdxModel) ]], \
    texture2d<float>      rmadTex   [[ texture(TexIdxRMAD)   ]]

#define COMMON_VS_PARAM frameInfo, vertexId, instanceId
#define COMMON_VS FRAME_INFO, VERT_DETAILS

#define COMMON_FS FRAME_INFO, LIGHTS, GBUFFER


inline float  unorm  (float  sn) { return (sn * 0.5 + 0.5); }
inline float2 unorm  (float2 sn) { return (sn * 0.5 + 0.5); }
inline float3 unorm  (float3 sn) { return (sn * 0.5 + 0.5); }

inline float  snorm  (float  un) { return (un * 2.0 - 1.0); }
inline float2 snorm  (float2 un) { return (un * 2.0 - 1.0); }
inline float3 snorm  (float3 un) { return (un * 2.0 - 1.0); }

inline float  inverse(float  v ) { return (1. - v); }
inline uint   inverse(uint   v ) { return (1  - v); }
inline int    inverse(int    v ) { return (1  - v); }

inline float  sqr    (float  v ) { return (v * v); }
inline float  max0   (float  v ) { return max(0.0, v); }
inline float  maxE   (float  v ) { return max(EPS, v); }

//
// float D_GGX(float NdotH, float roughness) {
//     float a = sqr(roughness);
//     float a2 = a * a;
//     float denom = sqr(NdotH * (a2 - 1.0) + 1.0);
//     return a2 / (PI * denom + 1e-5);
// }
//
// float G_Smith(float NdotV, float NdotL, float roughness) {
//     float k = sqr(roughness + 1.0) / 8.0;
//     float gv = NdotV / (NdotV * (1.0 - k) + k + 1e-5);
//     float gl = NdotL / (NdotL * (1.0 - k) + k + 1e-5);
//     return gv * gl;
// }
//
// float3 FresnelSchlickTinted(float cosTheta, float3 F0, float3 baseColor, float tint) {
//     float3 tintColor = baseColor / max(dot(baseColor, float3(1.0)), 1e-5);
//     return mix(F0, tintColor, tint) + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
// }
//
// float3 computeSheen(float3 H, float3 V, float3 baseColor, float sheen, float sheenTint) {
//     float3 Ctint = baseColor / max(dot(baseColor, float3(1.0)), 1e-5);
//     float3 Csheen = mix(float3(1.0), Ctint, sheenTint);
//     return sheen * Csheen * pow(1.0 - max(dot(H, V), 0.0), 5.0);
// }
//
// float D_GGX_Clearcoat(float NdotH, float roughness) {
//     float a = mix(0.1, 0.001, 1.0 - roughness);
//     float a2 = a * a;
//     float denom = sqr(NdotH * (a2 - 1.0) + 1.0);
//     return a2 / (PI * denom + 1e-5);
// }
//
// float G_Smith_Clearcoat(float NdotV, float NdotL) {
//     float k = 0.25; // fixed for clearcoat
//     float gv = NdotV / (NdotV * (1.0 - k) + k + 1e-5);
//     float gl = NdotL / (NdotL * (1.0 - k) + k + 1e-5);
//     return gv * gl;
// }
//
// float3 evaluateBRDF(Material mat, float3 pos, float3 viewDir, thread const Light* lights, uint lightCount) {
//     float3 N = normalize(mat.normal);
//     float3 V = normalize(viewDir);
//     float3 Lo = float3(0.0);
//
//     // Specular base reflectivity
//     float3 dielectricF0 = float3(0.04) * mat.specular;
//     float3 F0 = mix(dielectricF0, mat.color, mat.metallic);
//
//     for (uint i = 0; i < lightCount; ++i) {
//         Light light = lights[i];
//         float3 L = normalize(light.position - pos);
//         float3 H = normalize(V + L);
//
//         float NdotL = saturate(dot(N, L));
//         float NdotV = saturate(dot(N, V));
//         float NdotH = saturate(dot(N, H));
//         float HdotV = saturate(dot(H, V));
//
//         // --- Specular ---
//         float D = D_GGX(NdotH, mat.roughness);
//         float G = G_Smith(NdotV, NdotL, mat.roughness);
//         float3 F = FresnelSchlickTinted(HdotV, F0, mat.color, 1/*mat.specularTint*/);
//         float3 specular = D * G * F / (4.0 * NdotL * NdotV + 1e-5);
//
//         // --- Diffuse ---
//         float3 kd = (1.0 - F) * (1.0 - mat.metallic);
//         float3 diffuse = kd * mat.color / PI;
//
//         // --- Sheen ---
//         float3 sheenColor = computeSheen(H, V, mat.color, mat.sheen, mat.sheenTint);
//
//         // --- Clearcoat ---
//         float Dcc = D_GGX_Clearcoat(NdotH, mat.coatRoughness);
//         float Gcc = G_Smith_Clearcoat(NdotV, NdotL);
//         float Fcc = mix(0.04, 1.0, pow(1.0 - HdotV, 5.0));
//         float coat = mat.coatIOR > 1 ? 1 : 0;
//         float clearcoatSpec = coat * Dcc * Gcc * Fcc / (4.0 * NdotL * NdotV + 1e-5);
//
//         // Combine
//         float3 radiance = light.color * light.intensity;
//         Lo += (diffuse + specular + sheenColor + clearcoatSpec) * radiance * NdotL;
//     }
//
//     // Ambient term
//     float3 ambient = 0.03 * mat.color * mat.ao;
//     float3 finalColor = ambient + Lo;
//
//     // Tone map and gamma correct
//     finalColor = finalColor / (finalColor + float3(1.0));
//     finalColor = pow(finalColor, float3(1.0 / 2.2));
//
//     return finalColor;
// }
