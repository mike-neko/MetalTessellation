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
    
    // MARK: - Common
    var name = "TessellationRenderer"
    let renderState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState
    
    var vertexBuffer: MTLBuffer
    let vertexTexture: MTLTexture?
    let fragmentTexture: MTLTexture?
    
    var isActive = true
    var modelMatrix = matrix_identity_float4x4
    var baseMatrix: matrix_float4x4
    
    private let vertexCount: Int
    
    init(renderer: Renderer) {
        let device = renderer.device
        let library = renderer.library
        let mtkView = renderer.view!
        
        let model = Geometry(url: Bundle.main.url(forResource: "n", withExtension: "obj")!, device: device)!
        baseMatrix = matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), model.normalizeMatrix)
        vertexCount = model.vertexCount
        vertexBuffer = model.vertexBuffer
        
        let vertexDescriptor = model.vertexDescriptor
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertexDescriptor
        renderDescriptor.sampleCount = mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "tessellationTriangleVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "lambertFragment")
        renderDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        
        renderDescriptor.isTessellationFactorScaleEnabled = false
        renderDescriptor.tessellationFactorFormat = .half
        renderDescriptor.tessellationControlPointIndexType = .none
        renderDescriptor.tessellationFactorStepFunction = .constant
        renderDescriptor.tessellationOutputWindingOrder = .clockwise
        renderDescriptor.tessellationPartitionMode = .fractionalEven
        renderDescriptor.maxTessellationFactor = 16
        
        self.renderState = try! device.makeRenderPipelineState(descriptor: renderDescriptor)
        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        self.depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)
        
        let loader = MTKTextureLoader(device: device)
        self.vertexTexture = try! loader.newTexture(withContentsOf: Bundle.main.url(forResource: "d",
                                                                                    withExtension: "jpg")!,
                                                    options: nil)
        self.fragmentTexture = try! loader.newTexture(withContentsOf: Bundle.main.url(forResource: "checkerboard",
                                                                                      withExtension: "png")!,
                                                      options: nil)
        
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
    
    func update(renderer: Renderer) {
        let mat = Matrix.rotation(radians: Float(renderer.totalTime) * 0.5, axis: float3(0, 1, 0))
        modelMatrix = matrix_multiply(mat, baseMatrix)
    }
    
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(tessellationUniformsBuffer, offset: 0, at: 2)
        encoder.setTessellationFactorBuffer(tessellationFactorsBuffer, offset: 0, instanceStride: 0)
        encoder.drawPatches(numberOfPatchControlPoints: triangleVertex,
                            patchStart: 0,
                            patchCount: vertexCount / triangleVertex,
                            patchIndexBuffer: nil,
                            patchIndexBufferOffset: 0,
                            instanceCount: 1,
                            baseInstance: 0)
    }
    
    // MARK: -
    private func updateUniforms() {
        let p = tessellationUniformsBuffer.contents().assumingMemoryBound(to: TessellationUniforms.self)
        p.pointee.phongFactor = phongFactor
        p.pointee.displacementFactor = displacementFactor
        p.pointee.displacementOffset = displacementOffset
    }
}
