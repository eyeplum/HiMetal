//
//  MetalView2.swift
//  HiMetal
//
//  Created by Yan Li on 9/23/15.
//  Copyright © 2015 eyeplum. All rights reserved.
//

import Cocoa
import Metal
import QuartzCore

final class MetalView2: NSView
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
  
  var device: MTLDevice?
  var commandQueue: MTLCommandQueue?
  var metalLayer: CAMetalLayer? {
    set {
      layer = newValue
      wantsLayer = true
    }
    get {
      return layer as? CAMetalLayer
    }
  }
  
  var positionBuffer: MTLBuffer?
  var colorBuffer: MTLBuffer?
  
  var pipeline: MTLRenderPipelineState?
  
  var displayLink: CVDisplayLinkRef?
}

extension MetalView2
{
  
  struct Constants
  {
    static let vertexFunctionName = "vertex_main"
    static let fragmentFunctionName = "fragment_main"
  }
  
  private func setup()
  {
    buildDevice()
    buildVertexBuffers()
    buildPipline()
  }
  
  private func buildDevice()
  {
    device = MTLCreateSystemDefaultDevice()

    metalLayer = CAMetalLayer()
    metalLayer?.device = device
    metalLayer?.pixelFormat = .BGRA8Unorm
    
    commandQueue = device?.newCommandQueue()
  }
  
  private func buildVertexBuffers()
  {
    let positions: [Float] = [
       -1, -1, 0, 1,
        1, -1, 0, 1,
        0,  1, 0, 1,
    ]
    
    let colors: [Float] = [
      1, 0, 0, 1,
      0, 1, 0, 1,
      0, 0, 1, 1,
    ]
    
    positionBuffer = device?.newBufferWithBytes(positions,
      length: positions.count * sizeof(Float),
      options: .CPUCacheModeDefaultCache)
    
    colorBuffer = device?.newBufferWithBytes(colors,
      length: positions.count * sizeof(Float),
      options: .CPUCacheModeDefaultCache)
  }
  
  private func buildPipline()
  {
    let library = device?.newDefaultLibrary()
    
    let vertexFunction = library?.newFunctionWithName(Constants.vertexFunctionName)
    let fragmentFunction = library?.newFunctionWithName(Constants.fragmentFunctionName)
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer!.pixelFormat
    
    do
    {
      pipeline = try device?.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
    }
    catch
    {
      Swift.print("Error: pipeline initialization failed!")
      return
    }
  }
  
}

extension MetalView2
{
  
  private func redraw()
  {
    guard let drawable = metalLayer?.nextDrawable() else
    {
      Swift.print("Error: drawable not found.")
      return
    }
    
    let framebufferTexture = drawable.texture
    
    let renderPass = MTLRenderPassDescriptor()
    renderPass.colorAttachments[0].texture = framebufferTexture
    renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1)
    renderPass.colorAttachments[0].storeAction = .Store
    renderPass.colorAttachments[0].loadAction = .Clear
    
    guard let commandQueue = commandQueue else
    {
      Swift.print("Error: commandQueue not found.")
      return
    }
    
    let commandBuffer = commandQueue.commandBuffer()

    let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
    commandEncoder.setRenderPipelineState(pipeline!)
    commandEncoder.setVertexBuffer(positionBuffer, offset: 0, atIndex: 0)
    commandEncoder.setVertexBuffer(colorBuffer, offset: 0, atIndex: 1)
    commandEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
    commandEncoder.endEncoding()
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
  }
  
}

extension MetalView2
{
  
  override func viewDidMoveToWindow()
  {
    super.viewDidMoveToWindow()
    
    if let _ = superview
    {
      createDisplayLink()
    }
    else
    {
      destroyDisplayLink()
    }
  }
  
  private func displayLinkAction()
  {
    redraw()
  }
  
  private func createDisplayLink()
  {
    guard displayLink == nil else
    {
      return
    }
    
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
    
    guard let displayLink = displayLink else
    {
      Swift.print("Error: display link initialization failed!")
      return
    }
    
    let callback: CVDisplayLinkOutputCallback = { (_, _, _, _, _, userInfo) -> CVReturn in
      let this = Unmanaged<MetalView2>.fromOpaque(COpaquePointer(userInfo)).takeUnretainedValue()
      autoreleasepool {
        this.displayLinkAction()
      }
      return kCVReturnSuccess
    }
    
    let userInfo = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
    CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)
    CVDisplayLinkStart(displayLink)
  }
  
  private func destroyDisplayLink()
  {
    guard let displayLink = displayLink else
    {
      return
    }
    
    CVDisplayLinkStop(displayLink)
    self.displayLink = nil
  }
  
}
