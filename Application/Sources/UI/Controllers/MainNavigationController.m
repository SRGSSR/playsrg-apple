//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MainNavigationController.h"

#import "MiniPlayerView.h"
#import "NavigationController.h"

#import <libextobjc/libextobjc.h>
#import <MAKVONotificationCenter/MAKVONotificationCenter.h>
#import <Masonry/Masonry.h>

static const CGFloat MiniPlayerHeight = 50.f;

@interface MainNavigationController () <UINavigationControllerDelegate>

@property (nonatomic, weak) MiniPlayerView *miniPlayerView;

@property (nonatomic) NavigationController *navigationController;

@end

@implementation MainNavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController radioChannel:(RadioChannel *)radioChannel
{
    if (self = [super init]) {
        self.navigationController = [[NavigationController alloc] initWithRootViewController:rootViewController radioChannel:radioChannel];
        self.navigationController.delegate = self;
    }
    return self;
}

#pragma mark Getters and setters

- (NSArray<UIViewController *> *)viewControllers
{
    return self.navigationController.viewControllers;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.navigationController.view];
    [self.navigationController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    // The containment relationship must be established after the child view has been added so that layout guides
    // are correct (pre-iOS 11).
    [self addChildViewController:self.navigationController];
    
    // The mini player is not available for all BUs
    MiniPlayerView *miniPlayerView = [[MiniPlayerView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:miniPlayerView];
    
    // iOS 10 bug: Cannot apply a shadow to a blurred view without breaking the blur effect
    // Probably related to radar 27189321.
    // TODO: Remove when iOS 10 is not supported anymore
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 10) {
        miniPlayerView.layer.shadowOpacity = 0.9f;
        miniPlayerView.layer.shadowRadius = 5.f;
    }
    
    self.miniPlayerView = miniPlayerView;
    
    @weakify(self)
    [miniPlayerView addObserver:self keyPath:@keypath(miniPlayerView.active) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        [self updateLayoutAnimated:YES];
    }];
    
    [self updateLayoutAnimated:NO];
}

#pragma mark Rotation

- (BOOL)shouldAutorotate
{
    if (! [super shouldAutorotate]) {
        return NO;
    }
    
    return [self.navigationController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask supportedInterfaceOrientations = [super supportedInterfaceOrientations];
    return supportedInterfaceOrientations & [self.navigationController supportedInterfaceOrientations];
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.navigationController prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.navigationController preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.navigationController preferredStatusBarUpdateAnimation];
}

#pragma mark Layout

- (void)updateLayoutAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        if (self.miniPlayerView.active) {
            [self.miniPlayerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view);
                
                if (@available(iOS 11, *)) {
                    make.top.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(-MiniPlayerHeight);
                }
                else {
                    make.height.equalTo(@(MiniPlayerHeight));
                }
            }];
        }
        else {
            [self.miniPlayerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view);
                make.right.equalTo(self.view);
                make.bottom.equalTo(self.view);
                make.height.equalTo(@0);
            }];
        }
        
        [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
            [viewController play_setNeedsContentInsetsUpdate];
        }];
    };
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.2 animations:^{
            animations();
            [self.view layoutIfNeeded];
        }];
    }
    else {
        animations();
    }
}

#pragma mark Push and pop

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self.navigationController pushViewController:viewController animated:animated];
}

- (void)popViewControllerAnimated:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:animated];
}

- (void)popToRootViewControllerAnimated:(BOOL)animated
{
    [self.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark ContainerContentInsets protocol

- (UIEdgeInsets)play_additionalContentInsets
{
    return UIEdgeInsetsMake(0.f, 0.f, self.miniPlayerView.active ? MiniPlayerHeight : 0.f, 0.f);
}

#pragma mark UINavigationControllerDelegate protocol

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(mainNavigationController:willShowViewController:animated:)]) {
        [self.delegate mainNavigationController:self willShowViewController:viewController animated:animated];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.delegate respondsToSelector:@selector(mainNavigationController:didShowViewController:animated:)]) {
        [self.delegate mainNavigationController:self didShowViewController:viewController animated:animated];
    }
}

@end
