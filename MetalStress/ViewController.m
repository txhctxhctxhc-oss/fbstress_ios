#import "ViewController.h"
#import "Renderer.h"
#import <MetalKit/MetalKit.h>

@implementation ViewController {
    MTKView *_view;
    Renderer *_renderer;
}

- (void)loadView {
    self.view = [[MTKView alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = [[MTKView alloc] initWithFrame:self.view.bounds];
    _view.device = MTLCreateSystemDefaultDevice();
    _view.framebufferOnly = YES;

    [self.view addSubview:_view];

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    _view.delegate = _renderer;
}

@end
