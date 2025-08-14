//
//  PBR.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/08/10.
//


#import "Common.metal"

static float DistributionGGX(float NdotH, float alpha) {
    float a2 = sqr(alpha);
    float NdotH2 = sqr(NdotH);
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = M_PI_F * denom * denom;
    return a2 / denom;
}

static float GeometrySmith(float NdotV, float NdotL, float alpha) {
    float a2 = sqr(alpha);
//    float ggxv = NdotL * sqrt(NdotV * NdotV * (1.0 - a2) + a2);
//    float ggxl = NdotV * sqrt(NdotL * NdotL * (1.0 - a2) + a2);
//    return 0.5 / (ggxv + ggxl);
//    float r = (sqrt(alpha) + 1.0);
//    float k = (r * r) / 8.0;
    float ggxv = NdotV / (NdotV * (1.0 - a2) + a2);
    float ggxl = NdotL / (NdotL * (1.0 - a2) + a2);
    return ggxv * ggxl;
}

static float3 FresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(saturate(1.0 - cosTheta), 5.0);
}

static float3 FresnelSchlickTinted(float cosTheta, float3 F0, float3 baseColor, float tint) {
    float3 tintColor = baseColor / dot(baseColor, float3(1.0));
    float3 F0Tint = mix(F0, tintColor, tint);
    return F0Tint + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

static float3 computeSheen(float LdotH, float3 baseColor, float sheen, float sheenTint) {
    float3 tintColor = baseColor / dot(baseColor, float3(1.0));
    float3 sheenColor = mix(float3(1.0), tintColor, sheenTint);
    float sheenDistribution = pow(1.0 - max0(LdotH), 5.0);
    return sheen * sheenColor * sheenDistribution;
}

static void evaluateLighting(LIGHTS, Material mat, thread FragInfo& fi) {
    float3 N = normalize(mat.normal);
    float3 V = normalize(fi.viewDir);
    float NdotV = maxE(dot(N, V));
    
    fi.spec = float3(0.0);
    fi.diff = float3(0.0);
    fi.sheen = float3(0.0);
    fi.specCoat = float3(0.0);
    for (uint i = 0; i < lightInfo.pointLightCount; ++i) {
        PointLightLayout light = pointLights[i];
        float3 radiance = light.color * light.intensity;
        float3 L = normalize(light.position - fi.wpos);
        float3 H = normalize(V + L);

        float NdotL = max0(dot(N, L));
        float NdotH = max0(dot(N, H));
        float LdotH = max0(dot(L, H));
        float specDenom = (4.0 * NdotL * NdotV) + 1e-5;

        // --- Sheen ---
        float3 sheen = computeSheen(LdotH, mat.color, mat.sheen, mat.sheenTint);

        // --- Clearcoat ---
        float  DC   = DistributionGGX(NdotH, mat.coatRoughness2);
        float  GC   = GeometrySmith(NdotV, NdotL, mat.coatRoughness2);
        float3 FC   = FresnelSchlick(LdotH, float3(0.04));
        float3 specCoat = (DC * GC * FC) / specDenom;

        // --- Specular ---
        float  D    = DistributionGGX(NdotH, mat.roughness2);
        float  G    = GeometrySmith(NdotV, NdotL, mat.roughness2);
        float3 F    = FresnelSchlick(LdotH, mat.F0);
        float3 spec = (D * G * F) / specDenom;

        // --- Diffuse ---
        float3 kS = F;
        float3 kD = (1.0 - kS) * (1.0 - mat.metallic);
        float3 diff = kD * mat.color / M_PI_F;

        // Result
        fi.spec += spec * radiance * NdotL;
        fi.diff += diff * radiance * NdotL;
        fi.sheen += sheen * radiance * NdotL;
        fi.specCoat += specCoat * radiance * NdotL;
    }
}
