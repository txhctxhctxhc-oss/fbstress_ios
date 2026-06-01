#import "Renderer.h"

typedef struct {
    float time;
    int   pattern;
} Uniforms;

@interface Renderer ()
@property (nonatomic, strong) id<MTLDevice>              device;
@property (nonatomic, strong) id<MTLCommandQueue>        queue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipeline;
@property (nonatomic)         CFTimeInterval             startTime;

// GPU timing
@property (nonatomic, strong) id<MTLCounterSampleBuffer> counterBuffer; // nil on older HW
@property (nonatomic)         double                     lastGPUMs;
@property (nonatomic)         int                        pattern;
@end

@implementation Renderer

- (instancetype)initWithMetalKitView:(MTKView *)view {
    self = [super init];
    if (!self) return nil;

    self.device = view.device;
    self.queue  = [self.device newCommandQueue];

    id<MTLLibrary> lib = [self.device newDefaultLibrary];

    MTLRenderPipelineDescriptor *desc = [MTLRenderPipelineDescriptor new];
    desc.vertexFunction               = [lib newFunctionWithName:@"vertex_main"];
    desc.fragmentFunction             = [lib newFunctionWithName:@"fragment_main"];
    desc.colorAttachments[0].pixelFormat = view.colorPixelFormat;

    NSError *err = nil;
    self.pipeline = [self.device newRenderPipelineStateWithDescriptor:desc error:&err];
    if (err) NSLog(@"Pipeline error: %@", err);

    self.startTime = CACurrentMediaTime();
    self.lastGPUMs = 0.0;
    self.pattern   = 0;

    return self;
}

- (void)drawInMTKView:(MTKView *)view {
    CFTimeInterval cpuStart = CACurrentMediaTime();

    id<MTLCommandBuffer>        cmd  = [self.queue commandBuffer];
    MTLRenderPassDescriptor    *pass = view.currentRenderPassDescriptor;
    if (!pass) return;

    id<MTLRenderCommandEncoder> enc = [cmd renderCommandEncoderWithDescriptor:pass];
    [enc setRenderPipelineState:self.pipeline];

    float t      = (float)(CACurrentMediaTime() - self.startTime);
    int   pat    = (int)(t * 4.0f) % 8;
    self.pattern = pat;

    Uniforms u = { .time = t, .pattern = pat };
    [enc setFragmentBytes:&u length:sizeof(u) atIndex:0];
    [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [enc endEncoding];

    [cmd presentDrawable:view.currentDrawable];

    // Measure GPU time via CPU-side scheduling delta (simple approximation)
    __weak typeof(self) weakSelf = self;
    CFTimeInterval scheduleTime = CACurrentMediaTime();
    [cmd addCompletedHandler:^(id<MTLCommandBuffer> buf) {
        CFTimeInterval gpuEnd = CACurrentMediaTime();
        // buf.GPUStartTime / GPUEndTime available on iOS 14+
        double gpuMs;
        if (@available(iOS 14.0, *)) {
            gpuMs = (buf.GPUEndTime - buf.GPUStartTime) * 1000.0;
            if (gpuMs < 0 || gpuMs > 100) {
                // fallback: wall-clock delta from schedule to complete
                gpuMs = (gpuEnd - scheduleTime) * 1000.0;
            }
        } else {
            gpuMs = (gpuEnd - scheduleTime) * 1000.0;
        }
        weakSelf.lastGPUMs = gpuMs;
    }];

    [cmd commit];

    (void)cpuStart; // suppress unused warning
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

- (double)lastGPUTimeMilliseconds { return self.lastGPUMs; }
- (int)currentPattern             { return self.pattern;   }

@end
