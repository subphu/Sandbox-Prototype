//
//  UI.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/28.
//

#import "Common.metal"

struct LineOut {
    float4 position [[position]];
    float4 color;
};

vertex LineOut vs_grid(COMMON_VS) {
    const float length = 100.0;
    const int   pos = vertexId - 1;
    const int   dir = snorm(instanceId % 2);
    const int   dist = instanceId / 4 + 1;
    const int   axis = (instanceId / 2) % 2;
    const int   iaxis = inverse(axis);

    float4 wpos = float4(0, 0, 0, 1);
    wpos[axis * 2] = dist * dir;
    wpos[iaxis * 2] = pos * length;
    
    const float bold = (dist % 10) == 0 ? 1.6 : 0.6;
    const float depth = -(frameInfo.viewMatrix * wpos).z;
    const float apha = saturate(bold - depth * 0.01) * 0.5;
    
    LineOut out;
    out.color = float4(0, 0, 0, apha);
    out.position = frameInfo.viewProjMatrix * wpos;

    return out;
}

vertex LineOut vs_axis(COMMON_VS) {
    const float length = 100.0;
    const int   idx = instanceId * 2;
    const int   pos = vertexId - 1;
    
    LineOut out;
    out.color = float4(RGB_Light[idx], 0.2);
    out.position = float4(0, 0, 0, 1);
    out.position[idx] = pos * length;
    out.position = frameInfo.viewProjMatrix * out.position;

    return out;
}

fragment float4 fs_line(STAGE_IN(LineOut), COMMON_FS) {
    return in.color;
}
