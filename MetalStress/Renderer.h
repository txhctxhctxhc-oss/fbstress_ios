#import <MetalKit/MetalKit.h>

@interface Renderer : NSObject <MTKViewDelegate>
- (instancetype)initWithMetalKitView:(MTKView *)view;
- (double)lastGPUTimeMilliseconds;
- (int)currentPattern;
@end