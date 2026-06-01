#import "ViewController.h"
#import "Renderer.h"
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

// Pattern names matching Shaders.metal order
static NSString *kPatternNames[] = {
    @"FBM Clouds",
    @"Raymarched SDF",
    @"Mandelbrot",
    @"Julia Set",
    @"Voronoi+FBM",
    @"Full Stress"
};

@interface ViewController ()
@end

@implementation ViewController {
    MTKView        *_view;
    Renderer       *_renderer;
    UILabel        *_overlayLabel;
    CADisplayLink  *_displayLink;

    CFTimeInterval  _lastTime;
    NSUInteger      _frameCount;
    double          _fps;
    NSUInteger      _droppedFrames;
    CFTimeInterval  _startTime;

    // Thermal
    NSProcessInfoThermalState _thermalState;
}

- (void)loadView {
    self.view = [[MTKView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;
    _view.device                  = MTLCreateSystemDefaultDevice();
    _view.framebufferOnly         = YES;
    _view.preferredFramesPerSecond = 60;
    _view.backgroundColor         = UIColor.blackColor;

    _renderer      = [[Renderer alloc] initWithMetalKitView:_view];
    _view.delegate = _renderer;

    // ── Swipe gestures to change pattern ──
    UISwipeGestureRecognizer *swipeL = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(_swipeLeft)];
    swipeL.direction = UISwipeGestureRecognizerDirectionLeft;

    UISwipeGestureRecognizer *swipeR = [[UISwipeGestureRecognizer alloc]
        initWithTarget:self action:@selector(_swipeRight)];
    swipeR.direction = UISwipeGestureRecognizerDirectionRight;

    [self.view addGestureRecognizer:swipeL];
    [self.view addGestureRecognizer:swipeR];

    // ── Overlay label ──
    _overlayLabel = [[UILabel alloc] init];
    _overlayLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _overlayLabel.numberOfLines   = 0;
    _overlayLabel.font            = [UIFont monospacedSystemFontOfSize:11.5
                                                                weight:UIFontWeightMedium];
    _overlayLabel.textColor       = [UIColor colorWithWhite:1.0 alpha:0.95];
    _overlayLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.60];
    _overlayLabel.layer.cornerRadius    = 8.0;
    _overlayLabel.layer.masksToBounds   = YES;

    [self.view addSubview:_overlayLabel];

    [NSLayoutConstraint activateConstraints:@[
        [_overlayLabel.topAnchor constraintEqualToAnchor:
            self.view.safeAreaLayoutGuide.topAnchor constant:8],
        [_overlayLabel.leadingAnchor constraintEqualToAnchor:
            self.view.leadingAnchor constant:10],
        [_overlayLabel.widthAnchor constraintLessThanOrEqualToConstant:270],
    ]];

    // ── Hint label ──
    UILabel *hint = [[UILabel alloc] init];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text            = @"← swipe →  change pattern";
    hint.font            = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightRegular];
    hint.textColor       = [UIColor colorWithWhite:1.0 alpha:0.5];
    hint.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
    hint.layer.cornerRadius  = 6;
    hint.layer.masksToBounds = YES;
    hint.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:hint];
    [NSLayoutConstraint activateConstraints:@[
        [hint.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        [hint.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
    ]];

    // ── Thermal notifications ──
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(_thermalChanged:)
               name:NSProcessInfoThermalStateDidChangeNotification
             object:nil];
    _thermalState = [NSProcessInfo processInfo].thermalState;

    // ── DisplayLink ──
    _lastTime    = CACurrentMediaTime();
    _startTime   = _lastTime;
    _frameCount  = 0;
    _droppedFrames = 0;
    _fps         = 60.0;

    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_tick:)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_swipeLeft  { [_renderer nextPattern]; }
- (void)_swipeRight { [_renderer prevPattern]; }

- (void)_thermalChanged:(NSNotification *)n {
    _thermalState = [NSProcessInfo processInfo].thermalState;
}

static NSString *thermalString(NSProcessInfoThermalState s) {
    switch (s) {
        case NSProcessInfoThermalStateNominal:  return @"🟢 Nominal";
        case NSProcessInfoThermalStateFair:     return @"🟡 Fair";
        case NSProcessInfoThermalStateSerious:  return @"🟠 Serious";
        case NSProcessInfoThermalStateCritical: return @"🔴 Critical";
        default: return @"❓ Unknown";
    }
}

static NSString *batteryString(void) {
    UIDevice *dev = UIDevice.currentDevice;
    dev.batteryMonitoringEnabled = YES;
    float lvl = dev.batteryLevel;
    if (lvl < 0) return @"N/A";
    NSString *state = @"";
    switch (dev.batteryState) {
        case UIDeviceBatteryStateCharging:    state = @"⚡"; break;
        case UIDeviceBatteryStateFull:        state = @"🔋"; break;
        case UIDeviceBatteryStateUnplugged:   state = @"🔋"; break;
        default: break;
    }
    return [NSString stringWithFormat:@"%@%.0f%%", state, lvl * 100];
}

- (void)_tick:(CADisplayLink *)link {
    _frameCount++;
    CFTimeInterval now     = CACurrentMediaTime();
    CFTimeInterval elapsed = now - _lastTime;

    if (elapsed >= 0.5) {
        _fps        = _frameCount / elapsed;
        _frameCount = 0;
        _lastTime   = now;

        double gpuMs   = [_renderer lastGPUTimeMilliseconds];
        int    pat     = [_renderer currentPattern];
        double uptime  = now - _startTime;

        // Memory (resident set)
        int64_t memMB = 0;
        struct task_vm_info info;
        mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
        if (task_info(mach_task_self(), TASK_VM_INFO,
                      (task_info_t)&info, &count) == KERN_SUCCESS) {
            memMB = (int64_t)info.phys_footprint / (1024 * 1024);
        }

        NSString *patName = (pat >= 0 && pat < 6) ? kPatternNames[pat] : @"?";

        NSString *text = [NSString stringWithFormat:
            @"  ┌─ GPU STRESS ──────────────┐\n"
             "  │ FPS      %5.1f            │\n"
             "  │ Frame    %5.2f ms         │\n"
             "  │ GPU      %5.2f ms         │\n"
             "  │ Mem      %5lld MB          │\n"
             "  │ Thermal  %-18s│\n"
             "  │ Battery  %-18s│\n"
             "  │ Uptime   %5.0f s           │\n"
             "  │ Pattern  %d %-15s│\n"
             "  └───────────────────────────┘  ",
            _fps,
            1000.0 / MAX(_fps, 0.001),
            gpuMs,
            (long long)memMB,
            thermalString(_thermalState).UTF8String,
            batteryString().UTF8String,
            uptime,
            pat, patName.UTF8String
        ];

        dispatch_async(dispatch_get_main_queue(), ^{
            self->_overlayLabel.text = text;
            [self->_overlayLabel sizeToFit];
        });
    }
}

- (void)dealloc {
    [_displayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
