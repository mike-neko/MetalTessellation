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

    private var renderer: Renderer!

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

    // MARK: -
    private func setupMetal() {
        mtkView.sampleCount = 4
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
        
        renderer = Renderer(view: mtkView)
    }

    private func setupAsset() {
        let obj = TessellationRenderer(renderer: renderer)
        renderer.targets.append(obj)
    }
}

