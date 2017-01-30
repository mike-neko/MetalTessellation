//
//  Geometry.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/31.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import MetalKit

class Geometry {
    let vertexDescriptor: MTLVertexDescriptor
    let vertexCount: Int
    let vertexBuffer: MTLBuffer
    let normalizeMatrix: matrix_float4x4
    
    init(vertexBuffer: MTLBuffer, vertexCount: Int, vertexDescriptor: MTLVertexDescriptor, normalizeMatrix: matrix_float4x4) {
        self.vertexBuffer = vertexBuffer
        self.vertexCount = vertexCount
        self.vertexDescriptor = vertexDescriptor
        self.normalizeMatrix = normalizeMatrix
    }
    
    convenience init?(url: URL, device: MTLDevice) {
        let asset = MDLAsset(url: url,
                             vertexDescriptor: nil,
                             bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mesh: MTKMesh
        let normalizeMatrix: matrix_float4x4
        // 0決め打ち
        do {
            var mdlArray: NSArray?
            let mtkMeshes = try MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: &mdlArray)
            mesh = mtkMeshes[0]
            
            guard let mdl = mdlArray?[0] as? MDLMesh else { return nil }
            normalizeMatrix = Geometry.calcNormalizeMatrix(withMdlMesh: mdl)
        } catch {
            print(error)
            return nil
        }
        
        for a in mesh.vertexDescriptor.attributes.enumerated() {
            let b = a.1 as! MDLVertexAttribute
            print("\(a.0): " + b.name + " \(b.offset) \(b.bufferIndex) \(b.format.rawValue)")
        }
        
        /*
         pos float3, normal float3, tex float2
         */
        guard let attrPosition = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributePosition),
            attrPosition.format == .float3 else {
                return nil
        }
        let ofsPosition = attrPosition.offset / MemoryLayout<Float>.size
        guard let attrNormal = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeNormal),
            attrNormal.format == .float3 else {
                return nil
        }
        let ofsNormal = attrNormal.offset / MemoryLayout<Float>.size
        guard let attrTexcoord = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeTextureCoordinate),
            attrTexcoord.format == .float2 else {
                return nil
        }
        let ofsTexcoord = attrTexcoord.offset / MemoryLayout<Float>.size
        
        
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        let subMesh = mesh.submeshes[0]
        
        let indices: [UInt32]
        if subMesh.indexType == .uint16 {
            let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt16.self)
            indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map { UInt32($0) }
        } else {
            let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt32.self)
            indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map { $0 }
        }
        
        let count = vertexDescriptor.layouts[0].stride / MemoryLayout<Float>.size
        let p = mesh.vertexBuffers[0].buffer.contents().assumingMemoryBound(to: Float.self)
        let data = UnsafeBufferPointer(start: p, count: mesh.vertexCount * count)
        
        var buf = [Float]()
        print(data[1])
        indices.forEach {
            let i = Int($0) * count
            let pos = i + ofsPosition
            buf.append(contentsOf: data[pos..<pos + 3])
            let normal = i + ofsNormal
            buf.append(contentsOf: data[normal..<normal + 3])
            let texcoord = i + ofsTexcoord
            buf.append(contentsOf: data[texcoord..<texcoord + 2])
        }
        
        self.init(vertexBuffer: device.makeBuffer(bytes: &buf, length: MemoryLayout<Float>.stride * buf.count, options: []),
                  vertexCount: indices.count,
                  vertexDescriptor: vertexDescriptor,
                  normalizeMatrix: normalizeMatrix)
    }
    
    convenience init?(withMDLMesh mdl: MDLMesh, device: MTLDevice) {
        guard let mesh = try? MTKMesh(mesh: mdl, device: device) else { return nil }
        guard let vertex = Geometry.vertexFromMTK(mesh: mesh, device: device) else { return nil }
        
        self.init(vertexBuffer: vertex.buffer,
                  vertexCount: vertex.count,
                  vertexDescriptor: vertex.descriptor,
                  normalizeMatrix: Geometry.calcNormalizeMatrix(withMdlMesh: mdl))
    }
    
    private static func calcNormalizeMatrix(withMdlMesh mdl: MDLMesh) -> matrix_float4x4 {
        let diff = mdl.boundingBox.maxBounds - mdl.boundingBox.minBounds
        let scale = 1.0 / max(diff.x, max(diff.y, diff.z))
        let center = (mdl.boundingBox.maxBounds + mdl.boundingBox.minBounds) / vector_float3(2)
        return matrix_multiply(Matrix.scale(x: scale, y: scale, z: scale),
                               Matrix.translation(x: -center.x, y: -center.y, z: -center.z))
    }
    
    private static func vertexFromMTK(mesh: MTKMesh, device: MTLDevice) -> (buffer: MTLBuffer, count: Int, descriptor: MTLVertexDescriptor)? {
        for a in mesh.vertexDescriptor.attributes.enumerated() {
            let b = a.1 as! MDLVertexAttribute
            print("\(a.0): " + b.name + " \(b.offset) \(b.bufferIndex) \(b.format.rawValue)")
        }

        /*
         pos float3, normal float3, tex float2
         */
        guard let attrPosition = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributePosition),
            attrPosition.format == .float3 else {
                return nil
        }
        let ofsPosition = attrPosition.offset / MemoryLayout<Float>.size
        guard let attrNormal = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeNormal),
            attrNormal.format == .float3 else {
                return nil
        }
        let ofsNormal = attrNormal.offset / MemoryLayout<Float>.size
        guard let attrTexcoord = mesh.vertexDescriptor.attributeNamed(MDLVertexAttributeTextureCoordinate),
            attrTexcoord.format == .float2 else {
                return nil
        }
        let ofsTexcoord = attrTexcoord.offset / MemoryLayout<Float>.size
        
        
        let vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        let subMesh = mesh.submeshes[0]
        
        let indices: [UInt32]
        if subMesh.indexType == .uint16 {
            let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt16.self)
            indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map { UInt32($0) }
        } else {
            let pIndex = subMesh.indexBuffer.buffer.contents().assumingMemoryBound(to: UInt32.self)
            indices = UnsafeBufferPointer(start: pIndex, count: subMesh.indexCount).map { $0 }
        }
        
        let count = vertexDescriptor.layouts[0].stride / MemoryLayout<Float>.size
        let p = mesh.vertexBuffers[0].buffer.contents().assumingMemoryBound(to: Float.self)
        let data = UnsafeBufferPointer(start: p, count: mesh.vertexCount * count)
        
        var buf = [Float]()
        print(data[1])
        indices.forEach {
            let i = Int($0) * count
            let pos = i + ofsPosition
            buf.append(contentsOf: data[pos..<pos + 3])
            let normal = i + ofsNormal
            buf.append(contentsOf: data[normal..<normal + 3])
            let texcoord = i + ofsTexcoord
            buf.append(contentsOf: data[texcoord..<texcoord + 2])
        }
        
        return (buffer: device.makeBuffer(bytes: &buf, length: MemoryLayout<Float>.stride * buf.count, options: []),
                count: indices.count,
                descriptor: vertexDescriptor)
    }
}
