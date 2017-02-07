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
    private let defaultCameraMatrix = Matrix.lookAt(eye: float3(0, 2, 4), center: float3(), up: float3(0, 1, 0))
    
    @IBOutlet private weak var mtkView: MTKView!
    @IBOutlet private weak var tessellationFactorLabel: NSTextField!
    @IBOutlet private weak var phongFactorLabel: NSTextField!
    @IBOutlet private weak var infoLabel: NSTextField!

    private var renderer: Renderer!
    private var activeMeshRenderer: TessellationMeshRenderer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupMetal()
        setupAsset()
        mtkView.draw()
        
        checkFPS()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func checkFPS() {
        infoLabel.stringValue = String(format: "%.0f fps", 1 / renderer.drawTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkFPS()
        }
    }
    
    // MARK: -
    private func setupMetal() {
        mtkView.sampleCount = 4
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
        
        renderer = Renderer(view: mtkView)
        renderer.cameraMatrix = defaultCameraMatrix
        renderer.preUpdate = { [weak self] renderer in
//            self?.infoLabel.stringValue = String(format: "%.0f fps", 1 / renderer.deltaTime)
        }
    }

    
    private func setupAsset() {
        let ea = FileMesh.meshDisplacementMap(
            fileURL: Bundle.main.url(forResource: "Resources/earth/earth", withExtension: "obj")!,
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/earth/diffuse", withExtension: "jpg")!,
//            normalMapURL: Bundle.main.url(forResource: "models/earth/normal", withExtension: "jpg")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/earth/bump", withExtension: "jpg")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2.5, y: -2.5, z: 2.5), $0) })

        
//        let t = FileMesh.meshDisplacementMapWithFileURL(
//            Bundle.main.url(forResource: "models/ninja/ninja", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/ninja/ao", withExtension: "jpg")!,
////            normalMapURL: Bundle.main.url(forResource: "models/earth/normal", withExtension: "jpg")!,
//            displacementlMapURL: Bundle.main.url(forResource: "models/ninja/bump", withExtension: "jpg")!,
//            setupBaseMatrix: { return matrix_multiply($0, Matrix.scale(x: 2.5, y: 2.5, z: 2.5)) })
        
        let t = GeometryMesh.meshDisplacementMap(
            shapeType: .box(dimensions: vector_float3(1), segments: vector_uint3(4)),
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/metal/diffuse", withExtension: "png")!,
//            normalMapURL: Bundle.main.url(forResource: "Resources/metal/normal", withExtension: "png")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/metal/bump", withExtension: "png")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2, y: -2, z: 2), $0) })

//        let h = FileMesh.meshDisplacementMap(
//            fileURL: Bundle.main.url(forResource: "Resources/head/head", withExtension: "obj")!,
//            addNormalThreshold: 0.5,
//            diffuseTextureURL: Bundle.main.url(forResource: "Resources/head/diffuse", withExtension: "jpg")!,
//            displacementlMapURL: Bundle.main.url(forResource: "Resources/head/bump", withExtension: "png")!,
//            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })

        
        let fr = FileMesh.meshDisplacementMap(
            fileURL: Bundle.main.url(forResource: "Resources/frog/frog", withExtension: "obj")!,
            addNormalThreshold: 0.5,
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/white", withExtension: "png")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/frog/diffuse", withExtension: "bmp")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })
        
        let sphere = GeometryMesh.meshDisplacementMap(
            shapeType: .sphere(radii: vector_float3(1), segments: vector_uint2(4)),
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/brick/diffuse", withExtension: "png")!,
//            normalMapURL: Bundle.main.url(forResource: "Resources/brick/normal", withExtension: "png")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/checkerboard", withExtension: "png")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2, y: -2, z: 2), $0) })
        
        let t2 = GeometryMesh.meshDisplacementMap(
            shapeType: .box(dimensions: vector_float3(1), segments: vector_uint3(16)),
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/moji/diffuse", withExtension: "png")!,
            //            normalMapURL: Bundle.main.url(forResource: "Resources/metal/normal", withExtension: "png")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/moji/bump", withExtension: "jpg")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 2, y: -2, z: 2), $0) })
        let tt = GeometryMesh.meshDisplacementMap(
            shapeType: .triangle(dimensions: vector_float3(2)),
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/brick/diffuse", withExtension: "png")!,
            normalMapURL: Bundle.main.url(forResource: "Resources/brick/normal", withExtension: "png")!,
            displacementlMapURL: Bundle.main.url(forResource: "Resources/brick/bump", withExtension: "png")!,
            setupBaseMatrix: { return $0 })
        
        let meshRenderer = TessellationMeshRenderer(renderer: renderer, mesh:tt)
        meshRenderer.displacementFactor = 0.1
        meshRenderer.displacementOffset = 0
        meshRenderer.isTesselasiton = true
        renderer.targets.append(meshRenderer)
        
        
        activeMeshRenderer = meshRenderer
        

//        tessellationBox.isActive = false
        
//        let a = MeshRenderer(renderer: renderer)
//        renderer.targets.append(a)
//        let earth = FileMesh.meshLambertWithFileURL(
//            Bundle.main.url(forResource: "models/head/head", withExtension: "obj")!,
//            diffuseTextureURL: Bundle.main.url(forResource: "models/head/diffuse", withExtension: "jpg")!,
//            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })
        let earth = FileMesh.meshLambert(
            fileURL: Bundle.main.url(forResource: "Resources/earth/earth", withExtension: "obj")!,
            diffuseTextureURL: Bundle.main.url(forResource: "Resources/earth/diffuse", withExtension: "jpg")!,
            setupBaseMatrix: { return matrix_multiply(Matrix.scale(x: 4, y: 4, z: 4), $0) })
    }

    // MARK: - event
    @IBAction func toggleTessellation(sender: NSSegmentedCell) {
        activeMeshRenderer?.isTesselasiton = (sender.selectedSegment == 0)
    }
    
    @IBAction func tapWireFrame(sender: NSButton) {
        renderer.isWireFrame = (sender.state != 0)
    }
    
    @IBAction func changeTessellationFactor(sender: NSSlider) {
        activeMeshRenderer?.edgeFactor = sender.floatValue
        activeMeshRenderer?.insideFactor = sender.floatValue
        tessellationFactorLabel.stringValue = String(format: "%.02f", sender.floatValue)
    }
    
    @IBAction func changePhongFactor(sender: NSSlider) {
        activeMeshRenderer?.phongFactor = sender.floatValue
        phongFactorLabel.stringValue = String(format: "%.02f", sender.floatValue)
    }

    @IBAction func changeZoom(sender: NSSlider) {
        renderer.cameraMatrix = matrix_multiply(Matrix.translation(x: 0, y: 0, z: sender.floatValue),
                                                defaultCameraMatrix)

    }
}

