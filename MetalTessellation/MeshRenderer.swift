//
//  MeshRenderer.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/29.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import MetalKit

class MeshRenderer: RenderObject {
    // MARK: - Common
    var name = "MeshRenderer"
    let renderState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState

    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    let vertexTexture: MTLTexture? = nil
    let fragmentTexture: MTLTexture?

    var isActive = true
    var modelMatrix = matrix_identity_float4x4

    init(renderer: Renderer) {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        let mdlMesh = MDLMesh.newBox(withDimensions: vector_float3(2, 2, 1),
                                     segments: vector_uint3(2, 2, 2),
                                     geometryType: .triangles,
                                     inwardNormals: false,
                                     allocator: MTKMeshBufferAllocator(device: device))

        
//        let o = Geometry(withMDLMesh: mdlMesh, device: device)!
        let o = Geometry(url: Bundle.main.url(forResource: "a", withExtension: "obj")!, device: device)!
        modelMatrix = matrix_multiply(Matrix.scale(x: 2, y: 2, z: 2), o.normalizeMatrix)
        vertexCount = o.vertexCount
        vertexBuffer = o.vertexBuffer
        
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = o.vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "lambertFragment")
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        self.renderState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
        
        let loader = MTKTextureLoader(device: device)
        self.fragmentTexture = try! loader.newTexture(withContentsOf: Bundle.main.url(forResource: "checkerboard",
                                                                                      withExtension: "png")!,
                                                      options: nil)

    }
    
    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer) {
    }
    
    func update(renderer: Renderer) {
        modelMatrix = Matrix.rotation(radians: Float(renderer.totalTime) * 0.5, axis: float3(0, 1, 0))
    }
    
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder) {
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        
    }
}
