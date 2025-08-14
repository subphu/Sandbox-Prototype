//
//  Fullscreen.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/28.
//

#import "Common.metal"

vertex ScreenOut vs_screen(COMMON_VS) {
    ScreenOut out;
    float2 pos = float2(vertexId << 1 & 2, vertexId & 2);
    out.position = float4(pos * 2.0 - 1.0, 0.0, 1.0);
    out.texCoord = float2(pos.x, 1.0 - pos.y);
    return out;
}

fragment float4 fs_display(STAGE_IN(ScreenOut), COMMON_FS) {
    return float4(displayColor.sample(clampSampler, in.texCoord));
}
