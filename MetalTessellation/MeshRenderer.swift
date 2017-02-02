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
    var vertexTexture: MTLTexture?
    var fragmentTexture: MTLTexture?
    var normalMapTexture: MTLTexture?
    
    var isActive = true
    var modelMatrix = matrix_identity_float4x4
    var baseMatrix: matrix_float4x4
    
    init(renderer: Renderer, mesh: MeshObject) {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        //        let o = Geometry(withMDLMesh: mdlMesh, device: device)!
        let model = mesh.makeGeometory(renderer: renderer)!
        baseMatrix = mesh.setupBaseMatrix?(model.normalizeMatrix) ?? model.normalizeMatrix
        vertexCount = model.vertexCount
        vertexBuffer = model.vertexBuffer
        
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = model.vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: mesh.vertexFunctionName)
        renderDescriptor.fragmentFunction = library.makeFunction(name: mesh.fragmentFunctionName)
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        self.renderState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
        
        let loader = MTKTextureLoader(device: device)
        self.fragmentTexture = try! loader.newTexture(withContentsOf: mesh.diffuseTextureURL, options: nil)
        if let displacementMap = mesh.displacementMapTextureURL {
            self.vertexTexture = try? loader.newTexture(withContentsOf: displacementMap, options: nil)
        } else {
            self.vertexTexture = nil
        }
        if let normalMap = mesh.displacementMapTextureURL {
            self.normalMapTexture = try? loader.newTexture(withContentsOf: normalMap, options: nil)
        } else {
            self.normalMapTexture = nil
        }
        
    }
    
    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer) {
    }
    
    func update(renderer: Renderer) {
        let mat = Matrix.rotation(radians: Float(renderer.totalTime) * 0.5, axis: float3(0, 1, 0))
        modelMatrix = matrix_multiply(mat, baseMatrix)
    }
    
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(normalMapTexture, at: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
