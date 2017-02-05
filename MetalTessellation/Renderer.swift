//
//  Renderer.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/28.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Foundation
import MetalKit

protocol RenderObject {
    var name: String { get }
    var renderState: MTLRenderPipelineState { get }
    var depthStencilState: MTLDepthStencilState { get }
    
    var vertexBuffer: MTLBuffer { get }
    var vertexTexture: MTLTexture? { get }
    var fragmentTexture: MTLTexture? { get }
    
    var isActive: Bool { get set }
    var modelMatrix: matrix_float4x4 { get }
    var vertexCount: Int { get }
    
    func compute(renderer: Renderer, commandBuffer: MTLCommandBuffer)
    func update(renderer: Renderer)
    func render(renderer: Renderer, encoder: MTLRenderCommandEncoder)
}

class Renderer: NSObject, MTKViewDelegate {
    // MARK: Vertex
    struct Vertex {
        let position: float3
        let normal: float3
        let texcoord: float2
        
        static func vertexDescriptor() -> MTLVertexDescriptor {
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float4
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0;
            vertexDescriptor.attributes[1].format = .float3
            vertexDescriptor.attributes[1].offset = 16
            vertexDescriptor.attributes[1].bufferIndex = 0;
            vertexDescriptor.attributes[2].format = .float2
            vertexDescriptor.attributes[2].offset = 28
            vertexDescriptor.attributes[2].bufferIndex = 0;
            vertexDescriptor.layouts[0].stepRate = 1
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
            return vertexDescriptor
        }
    }
    
    enum VertexBufferIndex: Int {
        case vertexData = 0
        case frameUniformas
    }
    
    struct FrameUniforms {
        var projectionViewMatrinx: matrix_float4x4
        var normalMatrinx: matrix_float3x3
        var inverseViewMatrinx: matrix_float4x4
        var modelMatrinx: matrix_float4x4
        var wireColor: float4
    }
    
    // MARK: Camera
    struct CameraParameter {
        var fovY: Float
        var nearZ: Float
        var farZ: Float
    }
    
    var camera = CameraParameter(fovY: radians(fromDegrees: 65), nearZ: 0.1, farZ: 100)
    var projectionMatrix = matrix_float4x4()
    var cameraMatrix = Matrix.lookAt(eye: float3(0, 2, 4), center: float3(), up: float3(0, 1, 0))
    
    // MARK: Status
    private var lastTime = Date()
    private(set) var deltaTime = TimeInterval(0)
    private(set) var totalTime = TimeInterval(0)
    
    private(set) var totalVertexCount = 0
    
    var isWireFrame = false
    var wireColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1)
    
    // MARK: Renderer
    private let semaphore = DispatchSemaphore(value: 1)
    
    private(set) weak var view: MTKView!
    private(set) var device: MTLDevice
    private(set) var commandQueue: MTLCommandQueue
    private(set) var library: MTLLibrary
    private let frameUniformBuffer: MTLBuffer
    
    var preUpdate: ((Renderer) -> Void)? = nil
    
    var targets = [RenderObject]()

    init?(view: MTKView) {
        /* Metalの初期設定 */
        self.view = view
        
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        guard let library = device.newDefaultLibrary() else { return nil }
        self.library = library
        
        self.frameUniformBuffer = device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])
        
        super.init()
        
        view.device = device
        view.delegate = self
        projectionMatrix = Matrix.perspective(fovyRadians: camera.fovY,
                                              aspect: Float(view.drawableSize.width / view.drawableSize.height),
                                              nearZ: camera.nearZ,
                                              farZ: camera.farZ)
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        projectionMatrix = Matrix.perspective(fovyRadians: camera.fovY,
                                              aspect: Float(size.width / size.height),
                                              nearZ: camera.nearZ,
                                              farZ: camera.farZ)
    }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            semaphore.wait()
            
            guard let drawable = view.currentDrawable else { return }
            guard let renderDescriptor = view.currentRenderPassDescriptor  else { return }
            
            deltaTime = Date().timeIntervalSince(lastTime)
            lastTime = Date()
            totalTime += deltaTime

            let commandBuffer = commandQueue.makeCommandBuffer()
            compute(commandBuffer: commandBuffer)

            update()

            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor)
            render(encoder: renderEncoder)
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            
            commandBuffer.addCompletedHandler { _ in
                self.semaphore.signal()
            }
            
            commandBuffer.commit()
        }
    }
    
    // MARK: - private
    private func compute(commandBuffer: MTLCommandBuffer) {
        targets.forEach {
            guard $0.isActive else { return }
            $0.compute(renderer: self, commandBuffer: commandBuffer)
        }
    }
    
    private func update() {
        preUpdate?(self)
        targets.forEach {
            guard $0.isActive else { return }
            $0.update(renderer: self)
        }
    }

    private func render(encoder: MTLRenderCommandEncoder) {
        let fillMode: MTLTriangleFillMode = isWireFrame ? .lines : .fill
        totalVertexCount = 0

        targets.forEach {
            guard $0.isActive else { return }
            encoder.pushDebugGroup($0.name)
            
            encoder.setRenderPipelineState($0.renderState)
            encoder.setDepthStencilState($0.depthStencilState)
            
            updateFramUniforms(modelMatrinx: $0.modelMatrix)
            
            encoder.setVertexBuffer(frameUniformBuffer, offset: 0, at: VertexBufferIndex.frameUniformas.rawValue)
            encoder.setVertexBuffer($0.vertexBuffer, offset: 0, at: VertexBufferIndex.vertexData.rawValue)
            
            encoder.setVertexTexture($0.vertexTexture, at: 0)
            
            encoder.setFragmentTexture($0.fragmentTexture, at: 0)

            encoder.setTriangleFillMode(fillMode)
            
            $0.render(renderer: self, encoder: encoder)
            
            totalVertexCount += $0.vertexCount
        
            encoder.popDebugGroup()
        }
    }
 
    private func updateFramUniforms(modelMatrinx: matrix_float4x4) {
        let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
        let mat4 = matrix_multiply(cameraMatrix, modelMatrinx)
        p.pointee.projectionViewMatrinx = matrix_multiply(projectionMatrix, mat4)
        let mat3 = Matrix.toUpperLeft3x3(from4x4: mat4)
        p.pointee.normalMatrinx = matrix_invert(matrix_transpose(mat3))
        p.pointee.modelMatrinx = modelMatrinx
        p.pointee.inverseViewMatrinx = matrix_invert(cameraMatrix)
        let col = float4(Float(wireColor.redComponent), Float(wireColor.greenComponent),
                         Float(wireColor.blueComponent), isWireFrame ? 1 : 0)
        p.pointee.wireColor = col
    }
}
