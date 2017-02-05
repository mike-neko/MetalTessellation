//
//  Geometry+Shape.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/02/04.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import MetalKit

extension Geometry {
//    static func box(withDimensions dimensions: vector_float3, segments: vector_uint3, device: MTLDevice) -> Geometry? {
//        let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(1, 1, 1),
//                                     segments: vector_uint3(1, 1, 1),
//                                     geometryType: .triangles,
//                                     inwardNormals: false,
//                                     allocator: MTKMeshBufferAllocator(device: device))
//        return Geometry(withMDLMesh: mdlMesh, device: device)
//    }

    static func box(withDimensions dimensions: vector_float3, segments: vector_uint3, device: MTLDevice) -> Geometry? {
        let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(1, 1, 1),
                                     segments: vector_uint3(1, 1, 1),
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: MTKMeshBufferAllocator(device: device))
        return Geometry(withMDLMesh: mdlMesh, device: device)
    }
    
    
}
