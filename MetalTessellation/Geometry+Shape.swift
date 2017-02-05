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
    
    
}
