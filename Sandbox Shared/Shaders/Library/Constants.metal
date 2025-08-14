//
//  Constants.metal
//  Sandbox
//
//  Created by Subroto Hudiono on 2025/07/28.
//

#include <metal_stdlib>
#include <simd/simd.h>

#define EPS 1e-5

#define MAX8BIT  0xFF
#define RCP8BIT  0.003921568627

#define MAX12BIT 0xFFF
#define RCP12BIT 0.0002442002442

// System Colors (Default Light)
#define SYSTEM_RED_LIGHT    float3(1.0000, 0.2196, 0.2353)
#define SYSTEM_ORANGE_LIGHT float3(1.0000, 0.5529, 0.1569)
#define SYSTEM_YELLOW_LIGHT float3(1.0000, 0.8000, 0.0000)
#define SYSTEM_GREEN_LIGHT  float3(0.2039, 0.7804, 0.3490)
#define SYSTEM_MINT_LIGHT   float3(0.0000, 0.7843, 0.7020)
#define SYSTEM_TEAL_LIGHT   float3(0.0000, 0.7647, 0.8157)
#define SYSTEM_CYAN_LIGHT   float3(0.0000, 0.7529, 0.9098)
#define SYSTEM_BLUE_LIGHT   float3(0.0000, 0.5333, 1.0000)
#define SYSTEM_INDIGO_LIGHT float3(0.3804, 0.3333, 0.9608)
#define SYSTEM_PURPLE_LIGHT float3(0.7961, 0.1882, 0.8784)
#define SYSTEM_PINK_LIGHT   float3(1.0000, 0.1765, 0.3333)
#define SYSTEM_BROWN_LIGHT  float3(0.6745, 0.4980, 0.3686)

// System Colors (Default Dark)
#define SYSTEM_RED_DARK     float3(1.0000, 0.2588, 0.2706)
#define SYSTEM_ORANGE_DARK  float3(1.0000, 0.5725, 0.1882)
#define SYSTEM_YELLOW_DARK  float3(1.0000, 0.8392, 0.0000)
#define SYSTEM_GREEN_DARK   float3(0.1882, 0.8196, 0.3451)
#define SYSTEM_MINT_DARK    float3(0.0000, 0.8549, 0.7647)
#define SYSTEM_TEAL_DARK    float3(0.0000, 0.8235, 0.8784)
#define SYSTEM_CYAN_DARK    float3(0.2353, 0.8275, 0.9961)
#define SYSTEM_BLUE_DARK    float3(0.0000, 0.5686, 1.0000)
#define SYSTEM_INDIGO_DARK  float3(0.4196, 0.3647, 1.0000)
#define SYSTEM_PURPLE_DARK  float3(0.8588, 0.2039, 0.9490)
#define SYSTEM_PINK_DARK    float3(1.0000, 0.2157, 0.3725)
#define SYSTEM_BROWN_DARK   float3(0.7176, 0.5412, 0.4000)

// System Gray Colors (Default Light)
#define SYSTEM_GRAY_LIGHT   float3(0.5569, 0.5569, 0.5765)
#define SYSTEM_GRAY2_LIGHT  float3(0.6824, 0.6824, 0.6980)
#define SYSTEM_GRAY3_LIGHT  float3(0.7804, 0.7804, 0.8000)
#define SYSTEM_GRAY4_LIGHT  float3(0.8196, 0.8196, 0.8392)
#define SYSTEM_GRAY5_LIGHT  float3(0.8980, 0.8980, 0.9176)
#define SYSTEM_GRAY6_LIGHT  float3(0.9490, 0.9490, 0.9686)

// System Gray Colors (Default Dark)
#define SYSTEM_GRAY_DARK    float3(0.5569, 0.5569, 0.5765)
#define SYSTEM_GRAY2_DARK   float3(0.3882, 0.3882, 0.4000)
#define SYSTEM_GRAY3_DARK   float3(0.2824, 0.2824, 0.2902)
#define SYSTEM_GRAY4_DARK   float3(0.2275, 0.2275, 0.2353)
#define SYSTEM_GRAY5_DARK   float3(0.1725, 0.1725, 0.1804)
#define SYSTEM_GRAY6_DARK   float3(0.1098, 0.1098, 0.1176)

constexpr static constant float3 RGB_Light[] = { SYSTEM_RED_LIGHT, SYSTEM_GREEN_LIGHT, SYSTEM_BLUE_LIGHT };
constexpr static constant float3 RGB_Dark [] = { SYSTEM_RED_DARK , SYSTEM_GREEN_DARK , SYSTEM_BLUE_DARK  };

using namespace metal;

constexpr sampler clampSampler(mip_filter::linear,
                               mag_filter::linear,
                               min_filter::linear,
                               address::clamp_to_edge);

