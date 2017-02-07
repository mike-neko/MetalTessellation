//
//  Geometry+Shape.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/02/04.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import MetalKit

extension Geometry {
    static func box(withDimensions dimensions: vector_float3, segments: vector_uint3, device: MTLDevice) -> Geometry? {
        let mdlMesh = MDLMesh.newBox(withDimensions: dimensions,
                                     segments: segments,
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: MTKMeshBufferAllocator(device: device))
        return Geometry(withMDLMesh: mdlMesh, device: device)
    }

    static func sphere(withRadii radii: vector_float3, segments: vector_uint2, device: MTLDevice) -> Geometry? {
        let mdlMesh = MDLMesh.newEllipsoid(withRadii: radii,
                                           radialSegments: Int(segments.x), verticalSegments: Int(segments.y),
                                           geometryType: .triangles,
                                           inwardNormals: false,
                                           hemisphere: false,
                                           allocator: MTKMeshBufferAllocator(device: device))
        return Geometry(withMDLMesh: mdlMesh, device: device)
    }
    
    static func triangle(withDimensions dimensions: vector_float3, device: MTLDevice) -> Geometry? {
        let positions: [Vertex] = [
            Vertex(position: float3(-1, -1, 0), normal: float3(0, 0, 1), texcoord: float2(0, 1)),
            Vertex(position: float3(1, -1, 0), normal: float3(0, 0, 1), texcoord: float2(1, 1)),
            Vertex(position: float3(0, 1, 0), normal: float3(0, 0, 1), texcoord: float2(0.5, 0)),
            ]
        
        let list = positions.map {
            Vertex(position: $0.position * dimensions, normal: $0.normal, texcoord: $0.texcoord)
        }
        
        return Geometry.makeWith(vertexList: list, device: device)
    }
    
}
