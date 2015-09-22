//
//  MetalView.swift
//  HiMetal
//
//  Created by Yan Li on 9/21/15.
//  Copyright © 2015 eyeplum. All rights reserved.
//

import Cocoa
import Metal
import QuartzCore

final class MetalView: NSView
{
  
  override init(frame frameRect: NSRect)
  {
    super.init(frame: frameRect)
    setup()
  }
  
  required init?(coder: NSCoder)
  {
    super.init(coder: coder)
    setup()
  }
  
  private var metalLayer: CAMetalLayer? {
    return layer as? CAMetalLayer
  }
  
  private var commandQueue: MTLCommandQueue?
  
  private func setup()
  {
    layer = CAMetalLayer()
    wantsLayer = true
    
    guard let metalLayer = metalLayer else {
      fatalError("Metal Layer does not exist!")
    }
    
    metalLayer.device = MTLCreateSystemDefaultDevice()
    // metalLayer.pixelFormat = .RGBA8Unorm_sRGB
    commandQueue = metalLayer.device?.newCommandQueue()
  }
  
  override func viewDidMoveToWindow()
  {
    super.viewDidMoveToWindow()
    redraw()
  }
  
  private func redraw()
  {
    guard let metalLayer = metalLayer else {
      fatalError("Metal Layer does not exist!")
    }
    
    guard let commandQueue = commandQueue else {
      fatalError("Command Queue does not exist!")
    }
    
    guard let drawabel = metalLayer.nextDrawable() else {
      fatalError("No drawabel has found!")
    }
    
    let texture = drawabel.texture
    
    let passDescriptor = MTLRenderPassDescriptor()
    passDescriptor.colorAttachments[0].texture = texture
    passDescriptor.colorAttachments[0].loadAction = .Clear
    passDescriptor.colorAttachments[0].storeAction = .Store
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
    
    let commandBuffer = commandQueue.commandBuffer()

    let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(passDescriptor)
    commandEncoder.endEncoding()
    
    commandBuffer.presentDrawable(drawabel)
    commandBuffer.commit()
  }
    
}
