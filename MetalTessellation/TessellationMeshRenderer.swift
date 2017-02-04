//
//  TessellationMeshRenderer.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/29.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import MetalKit

class TessellationMeshRenderer: RenderObject {
    var isTesselasiton = false
    
    private let standardRenderState: MTLRenderPipelineState
    private let tesselasitonRenderState: MTLRenderPipelineState
    
    // MARK: Tesselasiton
    
    let triangleVertex = 3
    
    struct TessellationUniforms {
        var phongFactor: Float
        var displacementFactor: Float
        var displacementOffset: Float
    }
    
    private let tessellationFactorsBuffer: MTLBuffer
    private let tessellationUniformsBuffer: MTLBuffer
    
    var edgeFactor = UInt16(2)
    var insideFactor = UInt16(2)
    
    var phongFactor = Float(0) {
        didSet { updateUniforms() }
    }
    var displacementFactor = Float(0.1) {
        didSet { updateUniforms() }
    }
    var displacementOffset = Float(0) {
        didSet { updateUniforms() }
    }
    
    private let computePipeline: MTLComputePipelineState
    
    // MARK: - RenderObject Common
    var name = "MeshRenderer"
    
    var renderState: MTLRenderPipelineState {
        return isTesselasiton ? tesselasitonRenderState : standardRenderState
    }
    
    let depthStencilState: MTLDepthStencilState
    
    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    var vertexTexture: MTLTexture?
    var fragmentTexture: MTLTexture?
    var normalMapTexture: MTLTexture?
    
    var isActive = true
    var modelMatrix = matrix_identity_float4x4
    var baseMatrix: matrix_float4x4
    
    init(renderer: Renderer, mesh: TessellationMeshObject) {
        let device = renderer.device
        let library = renderer.library
        
        // make geometory
        //        let o = Geometry(withMDLMesh: mdlMesh, device: device)!
        let model = mesh.makeGeometory(renderer: renderer)!
        self.baseMatrix = mesh.setupBaseMatrix?(model.normalizeMatrix) ?? model.normalizeMatrix
        self.vertexCount = model.vertexCount
        self.vertexBuffer = model.vertexBuffer
        
        // make renderstate
        self.standardRenderState = TessellationMeshRenderer.makeStandardRenderState(
            renderer: renderer, vertexDescriptor: model.vertexDescriptor, mesh: mesh)
        self.tesselasitonRenderState = TessellationMeshRenderer.makeTessellationRenderState(
            renderer: renderer, vertexDescriptor: model.vertexDescriptor, mesh: mesh)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
        
        // make texture
        let loader = MTKTextureLoader(device: device)
        self.fragmentTexture = try! loader.newTexture(withContentsOf: mesh.diffuseTextureURL, options: nil)
        if let displacementMap = mesh.displacementMapURL {
            self.vertexTexture = try? loader.newTexture(withContentsOf: displacementMap, options: nil)
        } else {
            self.vertexTexture = nil
        }
        if let normalMap = mesh.displacementMapURL {
            self.normalMapTexture = try? loader.newTexture(withContentsOf: normalMap, options: nil)
        } else {
            self.normalMapTexture = nil
        }
        
        // init tessellation
        self.tessellationFactorsBuffer = device.makeBuffer(length: MemoryLayout<uint2>.stride,
                                                           options: .storageModePrivate)
        tessellationFactorsBuffer.label = "Tessellation Factors"
        self.tessellationUniformsBuffer = device.makeBuffer(length: MemoryLayout<TessellationUniforms>.stride,
                                                            options: .storageModeShared)
        tessellationUniformsBuffer.label = "Tessellation Uniforms"
        
        let kernel = library.makeFunction(name: "tessellationFactorsCompute")
        computePipeline = try! device.makeComputePipelineState(function: kernel!)
        
        updateUniforms()
    }
    
    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer) {
        if isTesselasiton {
            let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
            computeCommandEncoder.label = "Compute Tessellation Factors"
            computeCommandEncoder.pushDebugGroup("Compute Tessellation Factors")
            
            computeCommandEncoder.setComputePipelineState(computePipeline)
            
            var factor = uint2(UInt32(edgeFactor), UInt32(insideFactor))
            withUnsafePointer(to: &factor) {
                computeCommandEncoder.setBytes(UnsafeRawPointer($0), length: MemoryLayout<uint2>.stride, at: 0)
            }
            
            computeCommandEncoder.setBuffer(tessellationFactorsBuffer, offset: 0, at: 1)
            computeCommandEncoder.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1),
                                                       threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
            
            computeCommandEncoder.popDebugGroup()
            computeCommandEncoder.endEncoding()
        }
    }
    
    func update(renderer: Renderer) {
        // TODO: 仮
        let mat = Matrix.rotation(radians: Float(renderer.totalTime) * 0.5, axis: float3(0, 1, 0))
        modelMatrix = matrix_multiply(mat, baseMatrix)
    }
    
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder) {
        encoder.setFragmentTexture(normalMapTexture, at: 1)
        if isTesselasiton {
            encoder.setVertexBuffer(tessellationUniformsBuffer, offset: 0, at: 2)
            encoder.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
            encoder.drawPatches(numberOfPatchControlPoints: triangleVertex,
                                patchStart: 0,
                                patchCount: vertexCount / triangleVertex,
                                patchIndexBuffer: nil,
                                patchIndexBufferOffset: 0,
                                instanceCount: 1,
                                baseInstance: 0)
        } else {
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        }
    }
    
    // MARK: - private
    private static func makeStandardRenderState(renderer: Renderer, vertexDescriptor: MTLVertexDescriptor, mesh: MeshObject) -> MTLRenderPipelineState {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: mesh.vertexFunctionName)
        renderDescriptor.fragmentFunction = library.makeFunction(name: mesh.fragmentFunctionName)
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        return try! device.makeRenderPipelineState(descriptor: renderDescriptor)
    }
    
    private static func makeTessellationRenderState(renderer: Renderer, vertexDescriptor: MTLVertexDescriptor, mesh: TessellationMeshObject) -> MTLRenderPipelineState {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: mesh.tessellationVertexFunctionName)
        renderDescriptor.fragmentFunction = library.makeFunction(name: mesh.tessellationFragmentFunctionName)
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        
        renderDescriptor.isTessellationFactorScaleEnabled = false
        renderDescriptor.tessellationFactorFormat = .half
        renderDescriptor.tessellationControlPointIndexType = .none
        renderDescriptor.tessellationFactorStepFunction = .constant
        renderDescriptor.tessellationOutputWindingOrder = .clockwise
        renderDescriptor.tessellationPartitionMode = .fractionalEven
        renderDescriptor.maxTessellationFactor = 16
        
        return try! device.makeRenderPipelineState(descriptor: renderDescriptor)
    }

    private func updateUniforms() {
        let p = tessellationUniformsBuffer.contents().assumingMemoryBound(to: TessellationUniforms.self)
        p.pointee.phongFactor = phongFactor
        p.pointee.displacementFactor = displacementFactor
        p.pointee.displacementOffset = displacementOffset
    }
}
