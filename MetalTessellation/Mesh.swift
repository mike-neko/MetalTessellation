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
    var normalMapTextureURL: URL? { get }
    var displacementMapTextureURL: URL? { get }
}

struct FileMesh: MeshObject {
    let fileURL: URL
    
    let vertexFunctionName: String
    let fragmentFunctionName: String
    let diffuseTextureURL: URL
    let normalMapTextureURL: URL?
    let displacementMapTextureURL: URL?
    
    func makeGeometory(renderer: Renderer) -> Geometry? {
        return Geometry(url: fileURL, device: renderer.device)
    }
    
    let setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?
    
    
    static func meshLambertWithFileURL(_ fileURL: URL, diffuseTextureURL: URL,
                                       setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                        vertexFunctionName: "lambertVertex",
                        fragmentFunctionName: "lambertFragment",
                        diffuseTextureURL: diffuseTextureURL,
                        normalMapTextureURL: nil,
                        displacementMapTextureURL: nil,
                        setupBaseMatrix: setupBaseMatrix)
    }
    
    static func meshNormalMapWithFileURL(_ fileURL: URL, diffuseTextureURL: URL, normalMapTextureURL: URL,
                                         setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        return FileMesh(fileURL: fileURL,
                        vertexFunctionName: "bumpVertex",
                        fragmentFunctionName: "bumpFragment",
                        diffuseTextureURL: diffuseTextureURL,
                        normalMapTextureURL: normalMapTextureURL,
                        displacementMapTextureURL: nil,
                        setupBaseMatrix: setupBaseMatrix)
    }
    
    static func meshDisplacementMapWithFileURL(_ fileURL: URL, diffuseTextureURL: URL,
                                               normalMapTextureURL: URL? = nil, displacementlMapTextureURL: URL,
                                               setupBaseMatrix: ((matrix_float4x4) -> matrix_float4x4)?) -> FileMesh {
        let frag = (normalMapTextureURL != nil) ? "bumpFragment" : "lambertFragment"
        return FileMesh(fileURL: fileURL,
                        vertexFunctionName: "tessellationTriangleVertex",
                        fragmentFunctionName: frag,
                        diffuseTextureURL: diffuseTextureURL,
                        normalMapTextureURL: normalMapTextureURL,
                        displacementMapTextureURL: displacementlMapTextureURL,
                        setupBaseMatrix: setupBaseMatrix)
    }
    
    
}
