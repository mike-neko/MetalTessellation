//
//  LambertShader.metal
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/29.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

#include "Common.metal"

vertex VertexOut lambertVertex(VertexInput in [[ stage_in ]],
                               constant VertexUniforms& uniforms [[ buffer(1) ]]) {
    VertexOut out;
    out.position = uniforms.projectionViewMatrinx * float4(in.position, 1);
    out.texcoord = in.texcoord;
    out.normal = uniforms.normalMatrinx * in.normal;
    return out;
}

fragment half4 lambertFragment(VertexOut in [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    auto color = texture.sample(defaultSampler, in.texcoord);
    
    float diffuseFactor = saturate(dot(in.normal, -lightDirection));
    return half4(color * diffuseFactor);
}

