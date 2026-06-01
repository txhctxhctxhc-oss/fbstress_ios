#import "ViewController.h"
#import "Renderer.h"
#import <MetalKit/MetalKit.h>

@implementation ViewController {
    MTKView *_view;
    Renderer *_renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.framebufferOnly = YES;
    _view.preferredFramesPerSecond = 60;

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    _view.delegate = _renderer;
}

- (void)loadView {
    self.view = [[MTKView alloc] init];
}

@end