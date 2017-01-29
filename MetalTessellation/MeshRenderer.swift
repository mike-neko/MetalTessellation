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
    let mesh: MTKMesh

    // MARK: - Common
    var name = "MeshRenderer"
    let renderState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState
    
    var vertexBuffer: MTLBuffer {
        return mesh.vertexBuffers[0].buffer
    }
    
    let vertexTexture: MTLTexture? = nil
    let fragmentTexture: MTLTexture?

    var isActive = true
    var modelMatrix = matrix_identity_float4x4

    init(renderer: Renderer) {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        let asset = MDLAsset(url: Bundle.main.url(forResource: "a", withExtension: "obj")!,
                             vertexDescriptor: nil,
                             bufferAllocator: MTKMeshBufferAllocator(device: device))
        
        // 0決め打ち
        var mdlArray: NSArray?
        let mtkMeshes = try! MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: &mdlArray)
        self.mesh = mtkMeshes[0]
        
        let mdl = mdlArray![0] as! MDLMesh
                let diff = mdl.boundingBox.maxBounds - mdl.boundingBox.minBounds
                let scale = 1.0 / max(diff.x, max(diff.y, diff.z))
                let center = (mdl.boundingBox.maxBounds + mdl.boundingBox.minBounds) / vector_float3(2)
                let normalizeMatrix = matrix_multiply(Matrix.scale(x: scale, y: scale, z: scale),
                                                      Matrix.translation(x: -center.x, y: -center.y, z: -center.z))
        
                modelMatrix = matrix_multiply(Matrix.scale(x: 2, y: 2, z: 2), normalizeMatrix)
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
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
        let sub = mesh.submeshes[0]
        encoder.drawIndexedPrimitives(type: sub.primitiveType,
                                      indexCount: sub.indexCount,
                                      indexType: sub.indexType,
                                      indexBuffer: sub.indexBuffer.buffer,
                                      indexBufferOffset: sub.indexBuffer.offset)

    }
}
