//
//  Data.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/08/11.
//

#include <metal_stdlib>
#include <simd/simd.h>

#import "../ShaderTypes.h"
#import "Utils.metal"
#import "Constants.metal"

using namespace metal;

struct VertPosition {
    float3 position  [[attribute(VertAttrPosition)]];
};

struct VertGeometry {
    float3 position  [[attribute(VertAttrPosition)]];
    float3 normal    [[attribute(VertAttrNormal)]];
    float4 tangent   [[attribute(VertAttrTangent)]];
};

struct VertShading   {
    float3 position  [[attribute(VertAttrPosition)]];
    float3 normal    [[attribute(VertAttrNormal)]];
    float4 tangent   [[attribute(VertAttrTangent)]];
    float2 texCoord  [[attribute(VertAttrTexcoord0)]];
};

struct VertOut {
    float4 position [[position]];
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float2 texCoord;
    float3 worldPos;
    float3 viewPos;
};

struct ScreenOut {
    float4 position [[position]];
    float2 texCoord;
};

struct GBuffers {
    float4 tex0 [[color(0)]];
    float4 tex1 [[color(1)]];
    float4 tex2 [[color(2)]];
};

struct VertInfo {
    float3 position;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float2 texCoord;
    
    float4 wposition;
    float3 wnormal;
    float3 wtangent;
    float3 wbitangent;
    
    float4 vposition;
    float4 cposition;
    
    float  displacement;
    float3 displacedPos;
};

struct FragInfo {
    float3 wpos;
    float3 vpos;
    float2 uv;
    float2 coord;
    float2 motion;
    
    float  depth;
    float  zDist;
    
    float3 viewDir;
    float2 texCoord;
    
    float3 color;
    float3 diff;
    float3 spec;
    
    float3 specCoat;
    float3 sheen;
    
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float3x3 TBN;
};

static VertOut makeVertOut(VertInfo vi) {
    VertOut vo;
    vo.worldPos  = vi.wposition.xyz;
    vo.viewPos   = vi.vposition.xyz;
    vo.position  = vi.cposition;
    vo.texCoord  = vi.texCoord;
    vo.normal    = vi.wnormal;
    vo.tangent   = vi.wtangent;
    vo.bitangent = vi.wbitangent;
    return vo;
}

static VertInfo makeVertInfo(VertShading vs, FRAME_INFO, VERT_INFO) {
    VertInfo vi;
    vi.position  = vs.position;
    vi.texCoord  = vs.texCoord;
    vi.normal    = normalize(vs.normal);
    vi.tangent   = normalize(vs.tangent.xyz);
    vi.bitangent = normalize(cross(vi.normal, vi.tangent)) * vs.tangent.w;
    
    float4 rmadSample = rmadTex.sample(clampSampler, vi.texCoord.xy);
    float  dispScale  = 0.05;
    
    vi.displacement = snorm(rmadSample.a) * dispScale;
    vi.displacedPos = vi.position.xyz + vi.normal * vi.displacement;
    
    // Assuming uniform scale
    float3x3 worldNormal = float3x3(model.modelMatrix.columns[0].xyz,
                                    model.modelMatrix.columns[1].xyz,
                                    model.modelMatrix.columns[2].xyz);
    
    vi.wposition  = model.modelMatrix * float4(vi.displacedPos, 1);
    vi.wnormal    = normalize(worldNormal * vi.normal);
    vi.wtangent   = normalize(worldNormal * vi.tangent);
    vi.wbitangent = normalize(cross(vi.wnormal, vi.wtangent)) * vs.tangent.w;
        
    vi.vposition  = frameInfo.viewMatrix * vi.wposition;
    vi.cposition  = frameInfo.projMatrix * vi.vposition;
    
    return vi;
}

static FragInfo makeFragInfo(VertOut vo, FrameInfoLayout frameInfo) {
    FragInfo fi;
    fi.wpos  = vo.worldPos;
    fi.vpos  = vo.viewPos;
    fi.uv    = (vo.position.xy + 0.5) / frameInfo.resolution;
    fi.coord = vo.position.xy;
    fi.depth = vo.position.z;
    fi.zDist = vo.position.z / vo.position.w; // vo.viewPos.z
    
    fi.texCoord  = vo.texCoord;
    fi.normal    = vo.normal;
    fi.tangent   = vo.tangent;
    fi.bitangent = vo.bitangent;
    
    fi.TBN     = float3x3(fi.tangent, fi.bitangent, fi.normal);
    fi.viewDir = frameInfo.cameraPos - fi.wpos;
    
    return fi;
}

static FragInfo makeFragInfo(ScreenOut vo, FrameInfoLayout frameInfo, float3 normal, float depth) {
    FragInfo fi;
    fi.uv    = (vo.position.xy + 0.5) / frameInfo.resolution;
    fi.coord = vo.position.xy;
    fi.depth = depth;
    fi.texCoord  = vo.texCoord;
    
    float4 clipPos;
    clipPos.xy = snorm(fi.uv);
    clipPos.y  = -clipPos.y;
    clipPos.z = depth;
    clipPos.w = 1.0;
    
    float4 wpos = frameInfo.invViewProjMatrix * clipPos;
    fi.wpos = wpos.xyz / wpos.w;
    
    float4 vpos = frameInfo.invProjMatrix * clipPos;
    fi.vpos = vpos.xyz / vpos.w;
    
    float near = frameInfo.cameraNear;
    float far  = frameInfo.cameraFar;
    
    fi.zDist   = near * far / (far - depth * (far - near));
    fi.viewDir = frameInfo.cameraPos - fi.wpos;
    
    return fi;
}

//float2 calcMotionVector(float4 clipCurr, float4 clipPrev, float2 screenRes)
//{
//    // NDC coordinates (0..1)
//    float2 ndcCurr = clipCurr.xy / clipCurr.w * 0.5 + 0.5;
//    float2 ndcPrev = clipPrev.xy / clipPrev.w * 0.5 + 0.5;
//
//    // Pixel-space motion (you can remove *screenRes if you want normalized 0..1 motion)
//    return (ndcCurr - ndcPrev) * screenRes;
//}
