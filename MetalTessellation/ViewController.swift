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
        tessellationBox = TessellationMeshRenderer(renderer: renderer)
//        renderer.targets.append(tessellationBox)
//        tessellationBox.isActive = false
        let a = MeshRenderer(renderer: renderer)
        renderer.targets.append(a)
        
    }
}

