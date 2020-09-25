//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NavigationController.h"

#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface NavigationController ()

@property (nonatomic) UIStatusBarStyle statusBarStyle;

@end

@implementation NavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                                 tintColor:(UIColor *)tintColor
                           backgroundColor:(UIColor *)backgroundColor
                                 separator:(BOOL)separator
                            statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    if (self = [super initWithRootViewController:rootViewController]) {
        UINavigationBar *navigationBar = self.navigationBar;
        navigationBar.barStyle = UIBarStyleBlack;
        
        [self updateWithTintColor:tintColor backgroundColor:backgroundColor separator:separator statusBarStyle:statusBarStyle];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRootViewController:rootViewController tintColor:nil backgroundColor:nil separator:YES statusBarStyle:UIStatusBarStyleLightContent];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

#pragma mark Rotation

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.topViewController preferredStatusBarUpdateAnimation];
}

#pragma mark UI updates

- (void)updateWithTintColor:(UIColor *)tintColor backgroundColor:(UIColor *)backgroundColor separator:(BOOL)separator statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    self.statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
    
    UINavigationBar *navigationBar = self.navigationBar;
    
    if (backgroundColor) {
        navigationBar.barTintColor = backgroundColor;
        navigationBar.translucent = NO;
    }
    else {
        if (@available(iOS 13, *)) {
            navigationBar.barTintColor = nil;
        }
        else {
            navigationBar.barTintColor = UIColor.play_blurTintColor;
        }
        
        navigationBar.translucent = YES;
    }
    
    // See https://stackoverflow.com/a/19227158/760435
    if (separator) {
        [navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        navigationBar.shadowImage = nil;
    }
    else {
        [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        navigationBar.shadowImage = [UIImage new];
    }
    
    // Add a shadow for solid background to improve readability
    navigationBar.layer.shadowOpacity = (separator && backgroundColor != nil) ? 1.f : 0.f;
    
    UIColor *foregroundColor = tintColor ?: UIColor.whiteColor;
    navigationBar.tintColor = foregroundColor;
    navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithSize:18.f],
                                           NSForegroundColorAttributeName : foregroundColor };
    
    for (NSNumber *controlState in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled) ]) {
        [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[self.class]] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont srg_regularFontWithSize:16.f] }
                                                                                                   forState:controlState.integerValue];
    }
    
    [navigationBar setNeedsDisplay];
    
    // See https://stackoverflow.com/a/39543669/760435
    [navigationBar layoutIfNeeded];
}

- (void)updateWithRadioChannel:(RadioChannel *)radioChannel animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        UIStatusBarStyle darkStatusBarStyle = UIStatusBarStyleDefault;
        if (@available(iOS 13, *)) {
            darkStatusBarStyle = UIStatusBarStyleDarkContent;
        }
        UIStatusBarStyle statusBarStyle = radioChannel.hasDarkStatusBar ? darkStatusBarStyle : UIStatusBarStyleLightContent;
        [self updateWithTintColor:radioChannel.titleColor backgroundColor:radioChannel.color separator:YES statusBarStyle:statusBarStyle];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return YES;
    }
    else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    [self popToRootViewControllerAnimated:NO];
    
    UIViewController *rootViewController = self.viewControllers[0];
    if ([rootViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        UIViewController<PlayApplicationNavigation> *navigableRootViewController = (UIViewController<PlayApplicationNavigation> *)rootViewController;
        return [navigableRootViewController openApplicationSectionInfo:applicationSectionInfo];
    }
    else {
        return NO;
    }
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    if (self.viewControllers.count == 1) {
        UIViewController *rootViewController = self.viewControllers.firstObject;
        if ([rootViewController conformsToProtocol:@protocol(TabBarActionable)]) {
            UIViewController<TabBarActionable> *actionableRootViewController = (UIViewController<TabBarActionable> *)rootViewController;
            [actionableRootViewController performActiveTabActionAnimated:animated];
        }
    }
    else {
        // Natively performed when a navigation controller is directly embedded in a tab bar controller, but here triggered
        // explicitly for all other kinds of embedding as well (e.g. tab bar -> split view -> navigation).
        [self popToRootViewControllerAnimated:animated];
    }
}

@end
