#import "Renderer.h"

typedef struct {
    float time;
    int pattern;
} Uniforms;

@interface Renderer ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> queue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic) CFTimeInterval startTime;
@end

@implementation Renderer

- (instancetype)initWithMetalKitView:(MTKView *)view {
    self = [super init];
    if (!self) return nil;

    self.device = view.device;
    self.queue = [self.device newCommandQueue];

    id<MTLLibrary> lib = [self.device newDefaultLibrary];

    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction = [lib newFunctionWithName:@"vertex_main"];
    desc.fragmentFunction = [lib newFunctionWithName:@"fragment_main"];
    desc.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:desc error:nil];

    self.startTime = CACurrentMediaTime();

    return self;
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer> cmd = [self.queue commandBuffer];
    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    if (!pass) return;

    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];
    [enc setRenderPipelineState:self.pipeline];

    float t = CACurrentMediaTime() - self.startTime;

    Uniforms u;
    u.time = t;
    u.pattern = (int)(t * 0.5) % 6;

    [enc setFragmentBytes:&u length:sizeof(u) atIndex:0];

    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

    [enc endEncoding];
    [cmd presentDrawable:view.currentDrawable];
    [cmd commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end
