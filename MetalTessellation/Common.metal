//
//  Common.metal
//  MetalTessellation
//
//  Created by M.Ike on 2016/09/07.
//  Copyright © 2016年 M.Ike. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float3      position    [[ attribute(0) ]];
    float3      normal      [[ attribute(1) ]];
    float2      texcoord    [[ attribute(2) ]];
};

struct VertexUniforms {
    float4x4    projectionViewMatrinx;
    float3x3    normalMatrinx;
};

struct VertexOut {
    float4      position    [[ position ]];
    float3      normal;
    float2      texcoord;
};

#define lightDirection float3(0.1, -0.577, -1)
