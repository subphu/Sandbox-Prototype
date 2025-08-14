//
//  GBuffer.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/28.
//

#import "Common.metal"
#import "PBR.metal"

vertex VertOut vs_gbuffer(STAGE_IN(VertShading), COMMON_VS, VERT_INFO) {
    VertInfo vi = makeVertInfo(in, frameInfo, VERT_INFO_PARAM);
    return makeVertOut(vi);
}

fragment GBuffers fs_gbuffer(STAGE_IN(VertOut), COMMON_FS, MATERIALS) {
    FragInfo fi = makeFragInfo(in, frameInfo);
    Material mt = makeMaterial(MATERIALS_PARAM, fi);    
    return makeGBuffers(mt);
}

fragment float4 fs_lighting(STAGE_IN(ScreenOut), COMMON_FS) {
    float depth = depthTex.sample(clampSampler, in.texCoord).x;
    Material mt = makeMaterial(GBUFFER_PARAM, in.texCoord);
    FragInfo fi = makeFragInfo(in, frameInfo, mt.normal, depth);
    
    evaluateLighting(LIGHTS_PARAM, mt, fi);
    float3 color = fi.spec + fi.diff;
    color = pow(color, float3(1.0 / 2.2));
    return float4(color, 1.0);
}


