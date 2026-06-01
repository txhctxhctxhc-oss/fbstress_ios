#import "ViewController.h"
#import "Renderer.h"
#import <MetalKit/MetalKit.h>

@implementation ViewController {
    MTKView   *_view;
    Renderer  *_renderer;
    UILabel   *_overlayLabel;
    CADisplayLink *_displayLink;

    // FPS tracking
    CFTimeInterval _lastTime;
    NSUInteger     _frameCount;
    double         _fps;
}

- (void)loadView {
    self.view = [[MTKView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.framebufferOnly = YES;
    _view.preferredFramesPerSecond = 60;

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    _view.delegate = _renderer;

    // --- Overlay label ---
    _overlayLabel = [[UILabel alloc] init];
    _overlayLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _overlayLabel.numberOfLines = 0;
    _overlayLabel.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightMedium];
    _overlayLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    _overlayLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    _overlayLabel.layer.cornerRadius = 6.0;
    _overlayLabel.layer.masksToBounds = YES;
    _overlayLabel.textAlignment = NSTextAlignmentLeft;

    [self.view addSubview:_overlayLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_overlayLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [_overlayLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [_overlayLabel.widthAnchor constraintLessThanOrEqualToConstant:260],
    ]];

    // pad the label
    _overlayLabel.layer.sublayerTransform = CATransform3DMakeTranslation(0, 0, 0);

    // --- CADisplayLink for FPS measurement ---
    _lastTime   = CACurrentMediaTime();
    _frameCount = 0;
    _fps        = 0.0;

    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

static NSString *patternName(int p) {
    switch (p) {
        case 0: return @"Gradient Scroll";
        case 1: return @"Checkerboard";
        case 2: return @"Solid Red";
        case 3: return @"Hash Noise";
        case 4: return @"Sin Wave";
        case 5: return @"Cycle Fill";
        default: return @"Unknown";
    }
}

- (void)_tick:(CADisplayLink *)link {
    _frameCount++;
    CFTimeInterval now     = CACurrentMediaTime();
    CFTimeInterval elapsed = now - _lastTime;

    if (elapsed >= 0.5) {          // update every 0.5 s
        _fps        = _frameCount / elapsed;
        _frameCount = 0;
        _lastTime   = now;

        // frame time in ms
        double frameMs = (elapsed / MAX(_frameCount + 1, 1)) * 1000.0;
        // pull values from renderer
        double gpuMs   = [_renderer lastGPUTimeMilliseconds];
        int    pattern = [_renderer currentPattern];

        NSString *text = [NSString stringWithFormat:
            @"  FPS        %.1f\n"
             "  Frame      %.2f ms\n"
             "  GPU        %.2f ms\n"
             "  Pattern %d  %@\n"
             "  Time       %.1f s  ",
            _fps,
            1000.0 / MAX(_fps, 0.001),
            gpuMs,
            pattern, patternName(pattern),
            now];

        dispatch_async(dispatch_get_main_queue(), ^{
            self->_overlayLabel.text = text;
            [self->_overlayLabel sizeToFit];
        });
    }
}

- (void)dealloc {
    [_displayLink invalidate];
}

@end