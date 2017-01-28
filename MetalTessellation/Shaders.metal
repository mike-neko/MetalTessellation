//
//  Shaders.metal
//  tesse
//
//  Created by M.Ike on 2017/01/08.
//  Copyright (c) 2017年 M.Ike. All rights reserved.
//

#include <metal_stdlib>

using namespace metal;

struct VertexInput {
    float3      position    [[ attribute(0) ]];
    float3      normal      [[ attribute(1) ]];
    float2      texcoord    [[ attribute(2) ]];
};

struct VertexUniforms {
    float4x4    projectionView;
    float3x3    normal;
};

struct ShaderInOut {
    float4      position    [[ position ]];
    float3      color;
};

vertex ShaderInOut passThroughVertex(VertexInput in [[stage_in]],
                                     constant VertexUniforms& uniforms [[ buffer(1) ]]) {
    ShaderInOut out;
    out.position = uniforms.projectionView * float4(in.position, 1.0);
    out.color = in.normal;
    return out;
}

fragment float4 passThroughFragment(ShaderInOut in [[ stage_in ]]) {
    return float4(in.color, 1);
}
