//
//  Mesh.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/02/02.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import MetalKit

protocol MeshObject {
    func makeGeometory(renderer: Renderer) -> Geometry?
    var setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)? { get }
    var vertexFunctionName: String { get }
    var fragmentFunctionName: String { get }
    var diffuseTextureURL: URL { get }
    var normalMapURL: URL? { get }
}

protocol TessellationMeshObject: MeshObject {
    var tessellationVertexFunctionName: String { get }
    var tessellationFragmentFunctionName: String { get }
    var displacementMapURL: URL? { get }
}

struct FileMesh: MeshObject {
    let fileURL: URL
    
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    
    func makeGeometory(renderer: Renderer) -> Geometry? {
        return Geometry(url: fileURL, device: renderer.device)
    }
    
    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?
    
    
    static func meshLambert(fileURL: URL, diffuseTextureURL: URL,
                            setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                        vertexFunctionName: "lambertVertex",
                        fragmentFunctionName: "lambertFragment",
                        diffuseTextureURL: diffuseTextureURL,
                        normalMapURL: nil,
                        setupBaseMatrix: setupBaseMatrix)
    }
    
    static func meshNormalMap(fileURL: URL, diffuseTextureURL: URL, normalMapURL: URL,
                              setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                        vertexFunctionName: "bumpVertex",
                        fragmentFunctionName: "bumpFragment",
                        diffuseTextureURL: diffuseTextureURL,
                        normalMapURL: normalMapURL,
                        setupBaseMatrix: setupBaseMatrix)
    }
    
    static func meshDisplacementMap(fileURL: URL, addNormalThreshold: Float? = nil,
                                    diffuseTextureURL: URL,
                                    normalMapURL: URL? = nil, displacementlMapURL: URL,
                                    setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileTessellationMesh {
        return FileTessellationMesh(fileURL: fileURL,
                                    addNormalThreshold: addNormalThreshold,
                                    vertexFunctionName: "lambertVertex",
                                    fragmentFunctionName: "normalMapFragment",
                                    diffuseTextureURL: diffuseTextureURL,
                                    normalMapURL: normalMapURL,
                                    displacementMapURL: displacementlMapURL,
                                    tessellationVertexFunctionName: "tessellationTriangleVertex",
                                    tessellationFragmentFunctionName: "lambertFragment",
                                    setupBaseMatrix: setupBaseMatrix)
    }
    
}

struct FileTessellationMesh: TessellationMeshObject {
    let fileURL: URL
    let addNormalThreshold: Float?
    
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    let displacementMapURL: URL?
    
    let tessellationVertexFunctionName: String
    let tessellationFragmentFunctionName: String
    
    func makeGeometory(renderer: Renderer) -> Geometry? {
        return Geometry(url: fileURL, device: renderer.device, addNormalThreshold: addNormalThreshold)
    }
    
    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?
}

struct GeometryMesh: TessellationMeshObject {
    enum Shape {
        case triangle(dimensions: vector_float3)
        case box(dimensions: vector_float3, segments: vector_uint3)
        case sphere(radii: vector_float3, segments: vector_uint2)
    }
    
    let shapeType: Shape
    
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapURL: URL?
    let displacementMapURL: URL?
    
    let tessellationVertexFunctionName: String
    let tessellationFragmentFunctionName: String

    func makeGeometory(renderer: Renderer) -> Geometry? {
        switch shapeType {
        case .triangle(let dimensions):
            return Geometry.triangle(withDimensions: dimensions, device: renderer.device)
        case .box(let dimensions, let segments):
            return Geometry.box(withDimensions: dimensions, segments: segments, device: renderer.device)
        case .sphere(let radii, let segments):
            return Geometry.sphere(withRadii: radii, segments: segments, device: renderer.device)
        }
    }
    
    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?

    static func meshDisplacementMap(shapeType: Shape, diffuseTextureURL: URL,
                                    normalMapURL: URL? = nil, displacementlMapURL: URL,
                                    setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> GeometryMesh {
        return GeometryMesh(shapeType: shapeType,
                            vertexFunctionName: "lambertVertex",
                            fragmentFunctionName: "lambertFragment",
                            diffuseTextureURL: diffuseTextureURL,
                            normalMapURL: normalMapURL,
                            displacementMapURL: displacementlMapURL,
                            tessellationVertexFunctionName: "tessellationTriangleVertex",
                            tessellationFragmentFunctionName: "normalMapFragment",
                            setupBaseMatrix: setupBaseMatrix)
    }
}
