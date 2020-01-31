//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NavigationController.h"

#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>

@interface NavigationController ()

@property (nonatomic) UIStatusBarStyle statusBarStyle;

@property (nonatomic, weak) UIPanGestureRecognizer *panGestureRecognizer;

@property (nonatomic) BOOL loadedOnce;

@property (nonatomic, readonly) UIView *contentLayoutView;

@property (nonatomic) CGFloat lastNavigationBarYPosition;
@property (nonatomic) CGFloat originalNavigationBarYPosition;
@property (nonatomic) CGFloat originalContentViewYPosition;
@property (nonatomic) CGFloat originalContentViewHeight;

@end

@implementation NavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                                 tintColor:(UIColor *)tintColor
                           backgroundColor:(UIColor *)backgroundColor
                            statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.autorotationMode = HLSAutorotationModeContainerAndTopChildren;
        
        UINavigationBar *navigationBar = self.navigationBar;
        navigationBar.barStyle = UIBarStyleBlack;
        
        [self updateWithTintColor:tintColor backgroundColor:backgroundColor statusBarStyle:statusBarStyle];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRootViewController:rootViewController tintColor:nil backgroundColor:nil statusBarStyle:UIStatusBarStyleLightContent];
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

#pragma mark Getters and setters

- (UIView *)contentLayoutView
{
    return self.view.subviews.firstObject;
}

#pragma mark View lifecycle

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (! self.loadedOnce) {
        [self updateOriginalNavigationMetrics];
        self.loadedOnce = YES;
    }
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self updateOriginalNavigationMetrics];
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

#pragma mark Navigation bar

- (void)updateOriginalNavigationMetrics
{
    self.originalNavigationBarYPosition = CGRectGetMinY(self.navigationBar.frame);
    self.originalContentViewYPosition = CGRectGetMinY(self.contentLayoutView.frame);
    self.originalContentViewHeight = CGRectGetHeight(self.contentLayoutView.frame);
}

- (void)enableHideNavigationBarOnSwipeWithScrollView:(UIScrollView *)scrollView
{
    if (self.panGestureRecognizer) {
        [self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
    }
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGestureRecognizer.maximumNumberOfTouches = 1;
    panGestureRecognizer.delegate = self;
    panGestureRecognizer.cancelsTouchesInView = NO;
    [scrollView addGestureRecognizer:panGestureRecognizer];
    self.panGestureRecognizer = panGestureRecognizer;
}

- (void)showNavigationBarAnimated:(BOOL)animated
{
    [self setNavigationBarPosition:self.originalNavigationBarYPosition snap:NO animated:YES];
}

- (void)disableHideNavigationBarOnSwipeAnimated:(BOOL)animated
{
    [self.panGestureRecognizer.view removeGestureRecognizer:self.panGestureRecognizer];
    [self showNavigationBarAnimated:animated];
}

- (void)setNavigationBarPosition:(CGFloat)position snap:(BOOL)snap animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        CGFloat navigationBarHeight = CGRectGetHeight(self.navigationBar.frame);
        
        // 0 = Entirely visible, 1 = Entirely collapsed
        CGFloat progress = fmax(fmin((self.originalNavigationBarYPosition - position) / navigationBarHeight, 1.f), 0.f);
        if (snap) {
            progress = (progress <= 0.5f) ? 0.f : 1.f;
        }
        
        CGFloat yOffset = progress * navigationBarHeight;
        self.navigationBar.frame = CGRectMake(CGRectGetMinX(self.navigationBar.frame), self.originalNavigationBarYPosition - yOffset, CGRectGetWidth(self.navigationBar.frame), navigationBarHeight);
        self.contentLayoutView.frame = CGRectMake(CGRectGetMinX(self.contentLayoutView.frame), self.originalContentViewYPosition - yOffset, CGRectGetWidth(self.contentLayoutView.frame), self.originalContentViewHeight + yOffset);
        
        // TODO: - Fix opacity (flickering without titleView)
        //       - Fix navbar sometimes not opening with every pan (swipe up & down in a row; probably something with gesture
        //         recognizer states; layout does not break, though)
        //       - Issue if dismissing a modal in landscape on iPhone
        CGFloat alpha = 1.f - progress;
        [self.navigationBar.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == 0) {
                return;
            }
            
            if ([view isKindOfClass:UISearchBar.class]) {
                view.alpha = alpha;
            }
            else {
                [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull subview, NSUInteger idx, BOOL * _Nonnull stop) {
                    subview.alpha = alpha;
                }];
            }
        }];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.1 animations:animations];
    }
    else {
        animations();
    }
}

#pragma mark UI updates

- (void)updateWithTintColor:(UIColor *)tintColor backgroundColor:(UIColor *)backgroundColor statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    self.statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
    
    UINavigationBar *navigationBar = self.navigationBar;
    
    // Apply background colors with a small shadow for better readability
    if (backgroundColor) {
        navigationBar.layer.shadowOpacity = 1.f;
        
        navigationBar.barTintColor = backgroundColor;
        navigationBar.translucent = NO;
    }
    // Use standard blur with no shadow (which would break the blur).
    else {
        navigationBar.layer.shadowOpacity = 0.f;
        
        if (@available(iOS 13, *)) {
            navigationBar.barTintColor = nil;
        }
        else {
            navigationBar.barTintColor = UIColor.play_blurTintColor;
        }
        
        navigationBar.translucent = YES;
    }
    
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
        [self updateWithTintColor:radioChannel.titleColor backgroundColor:radioChannel.color statusBarStyle:statusBarStyle];
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

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint velocity = [gestureRecognizer velocityInView:gestureRecognizer.view];
    return fabs(velocity.y) > fabs(velocity.x);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark Gesture reognizers

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGFloat yOffset = [gestureRecognizer translationInView:gestureRecognizer.view].y;
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            self.lastNavigationBarYPosition = CGRectGetMinY(self.navigationBar.frame);
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            [self setNavigationBarPosition:self.lastNavigationBarYPosition + yOffset snap:NO animated:NO];
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            [self setNavigationBarPosition:self.lastNavigationBarYPosition + yOffset snap:YES animated:YES];
            break;
        }
            
        default: {
            break;
        }
    }
}

@end
