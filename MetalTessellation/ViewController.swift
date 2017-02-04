//
//  ViewController.swift
//  MetalTessellation
//
//  Created by M.Ike on 2017/01/28.
//  Copyright © 2017年 M.Ike. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    
    @IBOutlet private weak var mtkView: MTKView!
    @IBOutlet private weak var tessellationFactorLabel: NSTextField!
    @IBOutlet private weak var phongFactorLabel: NSTextField!

    private var renderer: Renderer!
    private var tessellationBox: TessellationMeshRenderer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupMetal()
        setupAsset()
        mtkView.draw()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func tapWireFrame(sender: NSButton) {
        renderer.isWireFrame = (sender.state != 0)
    }

    @IBAction func changeTessellationFactor(sender: NSSlider) {
        tessellationBox.edgeFactor = UInt16(sender.integerValue)
        tessellationBox.insideFactor = UInt16(sender.integerValue)
        tessellationFactorLabel.integerValue = sender.integerValue
    }
    
    @IBAction func changePhongFactor(sender: NSSlider) {
        tessellationBox.phongFactor = sender.floatValue
        phongFactorLabel.stringValue = String(format: "%.02f", sender.floatValue)
    }

    
    // MARK: -
    private func setupMetal() {
        mtkView.sampleCount = 4
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
        
        renderer = Renderer(view: mtkView)
    }

    
    
    
    private func setupAsset() {
//        let t = FileMesh.meshDisplacementMap(
//            fileURL: Bundle.main.url(forResource: "models/earth/earth", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/earth/diffuse", withExtension: "jpg")!,
////            normalMapURL: Bundle.main.url(forResource: "models/earth/normal", withExtension: "jpg")!,
//            displacementlMapURL: Bundle.main.url(forResource: "models/earth/bump", withExtension: "jpg")!,
//            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2, y: -2, z: 2), $0) })

        
//        let t = FileMesh.meshDisplacementMapWithFileURL(
//            Bundle.main.url(forResource: "models/ninja/ninja", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/ninja/ao", withExtension: "jpg")!,
////            normalMapURL: Bundle.main.url(forResource: "models/earth/normal", withExtension: "jpg")!,
//            displacementlMapURL: Bundle.main.url(forResource: "models/ninja/bump", withExtension: "jpg")!,
//            setupBaseMatrix: { return matrix_multiply($0, Matrix.scale(x: 2.5, y: 2.5, z: 2.5)) })
        
//        let t = FileMesh.meshDisplacementMapWithFileURL(
//            Bundle.main.url(forResource: "models/head/head", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/head/diffuse", withExtension: "jpg")!,
//            //            normalMapURL: Bundle.main.url(forResource: "models/earth/normal", withExtension: "jpg")!,
//            displacementlMapURL: Bundle.main.url(forResource: "models/head/bump", withExtension: "png")!,
//            setupBaseMatrix: { return matrix_multiply($0, Matrix.scale(x: 2.5, y: 2.5, z: 2.5)) })
        
        let t = GeometryMesh.meshDisplacementMap(
            shapeType: .box(dimensions: vector_float3(1, 1, 1), segments: vector_uint3(1)),
            diffuseTextureURL: Bundle.main.url(forResource: "models/earth/diffuse", withExtension: "jpg")!,
            displacementlMapURL: Bundle.main.url(forResource: "models/earth/bump", withExtension: "jpg")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2, y: -2, z: 2), $0) })
        
        tessellationBox = TessellationMeshRenderer(renderer: renderer, mesh:t)
        tessellationBox.displacementFactor = 0.0213
        tessellationBox.displacementOffset = 0
        tessellationBox.isTesselasiton = true
        renderer.targets.append(tessellationBox)
        
        
        
//        tessellationBox.isActive = false
        
//        let a = MeshRenderer(renderer: renderer)
//        renderer.targets.append(a)
//        let earth = FileMesh.meshLambertWithFileURL(
//            Bundle.main.url(forResource: "models/head/head", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/head/diffuse", withExtension: "jpg")!,
//            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })
        let earth = FileMesh.meshLambert(
            fileURL: Bundle.main.url(forResource: "models/earth/earth", withExtension: "obj")!,
            diffuseTextureURL: Bundle.main.url(forResource: "models/earth/diffuse", withExtension: "jpg")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })
    }
}

