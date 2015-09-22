//
//  Shaders.metal
//  HiMetal
//
//  Created by Yan Li on 9/23/15.
//  Copyright © 2015 eyeplum. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ColoredVertex
{
  float4 position [[position]];
  float4 color;
};

vertex ColoredVertex vertex_main(constant float4 *position [[buffer(0)]],
                                 constant float4 *color [[buffer(1)]],
                                 uint vid [[vertex_id]])
{
  ColoredVertex vert;
  vert.position = position[vid];
  vert.color = color[vid];
  return vert;
}

fragment float4 fragment_main(ColoredVertex vert [[stage_in]])
{
  return vert.color;
}
