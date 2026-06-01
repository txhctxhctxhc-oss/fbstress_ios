#import "Renderer.h"

typedef struct {
    float  time;
    int    pattern;
    float  resX;
    float  resY;
} Uniforms;

static const int kPatternCount = 6;

@interface Renderer ()
@property (nonatomic, strong) id<MTLDevice>              device;
@property (nonatomic, strong) id<MTLCommandQueue>        queue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic)         CFTimeInterval             startTime;
@property (nonatomic)         double                     lastGPUMs;
@property (nonatomic)         int                        pattern;
@end

@implementation Renderer

- (instancetype)initWithMetalKitView:(MTKView *)view {
    self = [super init];
    if (!self) return nil;

    self.device    = view.device;
    self.queue     = [self.device newCommandQueue];
    self.startTime = CACurrentMediaTime();
    self.pattern   = 0;

    id<MTLLibrary> lib = [self.device newDefaultLibrary];
    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction               = [lib newFunctionWithName:@"vertex_main"];
    desc.fragmentFunction             = [lib newFunctionWithName:@"fragment_main"];
    desc.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    NSError *err = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:desc error:&err];
    if (err) NSLog(@"Pipeline error: %@", err);

    return self;
}

- (void)drawInMTKView:(MTKView *)view {
    id<MTLCommandBuffer>        cmd  = [self.queue commandBuffer];
    MTLRenderPassDescriptor    *pass = view.currentRenderPassDescriptor;
    if (!pass) return;

    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];
    [enc setRenderPipelineState:self.pipeline];

    float t = (float)(CACurrentMediaTime() - self.startTime);

    Uniforms u;
    u.time    = t;
    u.pattern = self.pattern;
    u.resX    = (float)view.drawableSize.width;
    u.resY    = (float)view.drawableSize.height;

    [enc setFragmentBytes:&u length:sizeof(u) atIndex:0];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [enc endEncoding];
    [cmd presentDrawable:view.currentDrawable];

    __weak typeof(self) weakSelf = self;
    CFTimeInterval scheduleTime = CACurrentMediaTime();
    [cmd addCompletedHandler:^(id<MTLCommandBuffer> buf) {
        double gpuMs;
        if (@available(iOS 14.0, *)) {
            gpuMs = (buf.GPUEndTime - buf.GPUStartTime) * 1000.0;
            if (gpuMs <= 0 || gpuMs > 200)
                gpuMs = (CACurrentMediaTime() - scheduleTime) * 1000.0;
        } else {
            gpuMs = (CACurrentMediaTime() - scheduleTime) * 1000.0;
        }
        weakSelf.lastGPUMs = gpuMs;
    }];

    [cmd commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (void)nextPattern { self.pattern = (self.pattern + 1) % kPatternCount; }
- (void)prevPattern { self.pattern = (self.pattern - 1 + kPatternCount) % kPatternCount; }
- (double)lastGPUTimeMilliseconds { return self.lastGPUMs; }
- (int)currentPattern             { return self.pattern;   }

@end
