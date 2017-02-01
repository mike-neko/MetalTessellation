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
    out.position = uniforms.projectionViewMatrix * float4(in.position, 1);
    out.texcoord = in.texcoord;
    out.normal = uniforms.normalMatrix * in.normal;
    return out;
}

fragment half4 lambertFragment(VertexOut in [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    auto color = texture.sample(defaultSampler, in.texcoord);
    
    float diffuseFactor = saturate(dot(in.normal, -lightDirection));
    return half4(color * diffuseFactor);
}

#define lightWorldPosition float3(0.1, -0.577, -1)
#define eyeWorldPosition float3(0.1, -0.577, -1)


vertex BumpOut bumpVertex(VertexInput in [[ stage_in ]],
                          constant VertexUniforms& uniforms [[ buffer(1) ]]) {
    BumpOut out;
    out.position = uniforms.projectionViewMatrix * float4(in.position, 1);
    out.texcoord = in.texcoord;
    
    auto N = (uniforms.normalMatrix * in.normal).xyz;
    auto T = normalize(cross(N, float3(0, 1, 0)));
    auto B = cross(N, T);
    
    auto L = (uniforms.inverseViewMatrix * float4(lightWorldPosition, 1)).xyz;
    auto worldPos = uniforms.modelMatrix * float4(in.position, 1);
    auto eye = eyeWorldPosition - worldPos.xyz;
    
    out.light = float3(dot(L, T), dot(L, B), dot(L, N));
    out.eye = float3(dot(eye, T), dot(eye, B), dot(eye, N));
    return out;
}

fragment half4 bumpFragment(BumpOut in [[ stage_in ]],
                            texture2d<float> texture [[ texture(0) ]],
                            texture2d<float> normalmap [[ texture(1) ]]) {
    constexpr sampler defaultSampler;
    auto decal = texture.sample(defaultSampler, in.texcoord);
    auto normal = (normalmap.sample(defaultSampler, in.texcoord) - 0.5).rgb;
    auto N = normalize(normal);
    auto L = normalize(in.light);
    auto V = normalize(in.eye);
    auto H = normalize(L + V);
    auto NL = saturate(dot(N, L));
    auto NH = saturate(dot(N, H));
    
    auto diffuse = decal.rgb * NL;
    auto specular = pow(NH, 0.5) * 0.5;
    
    auto color = half3(diffuse + specular);
    return half4(color, 1);
}
