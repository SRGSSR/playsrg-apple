//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ModalTransition.h"

// For implementation details, see
//   https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1

@interface ModalTransition ()

@property (nonatomic) BOOL presentation;
@property (nonatomic) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic) CGFloat progress;

@property (nonatomic, weak) UIView *dimmingView;

@end

@implementation ModalTransition

#pragma mark Object lifecycle

- (instancetype)initForPresentation:(BOOL)presentation
{
    if (self = [super init]) {
        self.presentation = presentation;
    }
    return self;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initForPresentation:YES];
}

#pragma mark Getters and setters

- (BOOL)wasCancelled
{
    return self.transitionContext.transitionWasCancelled;
}

#pragma mark Common transition implementation

- (void)setupTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    UIView *containerView = [transitionContext containerView];
    
    UIView *dimmingView = [[UIView alloc] initWithFrame:containerView.bounds];
    dimmingView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.5f];
    self.dimmingView = dimmingView;
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.presentation) {
        NSAssert(toViewController.modalPresentationStyle == UIModalPresentationCustom, @"A custom modal presentation style must be used");
        
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        NSAssert(toView != nil, @"Presented view must be available");
        [containerView addSubview:toView];
        [containerView insertSubview:dimmingView belowSubview:toView];
    }
    else {
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        NSAssert(fromView != nil, @"Dismissed view must be available");
        [containerView insertSubview:dimmingView belowSubview:fromView];
    }
    
    dimmingView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [dimmingView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [dimmingView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
        [dimmingView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [dimmingView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor]
    ]];
    
    // Appearance events need to be notified manually for custom transitions, see https://stackoverflow.com/a/29041911/760435
    [fromViewController beginAppearanceTransition:NO animated:transitionContext.animated];
    [toViewController beginAppearanceTransition:YES animated:transitionContext.animated];
    
    [self updateTransition:transitionContext withProgress:0.f];
}

- (void)updateTransition:(id<UIViewControllerContextTransitioning>)transitionContext withProgress:(CGFloat)progress
{
    NSParameterAssert(transitionContext);
    
    UIView *containerView = [transitionContext containerView];
    
    // Clamp to [0; 1]
    progress = fmaxf(fminf(1.f, progress), 0.f);
    
    if (self.presentation) {
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        NSAssert(toView != nil, @"Presented view must be available");
        toView.frame = CGRectMake(0.f,
                                  (1.f - progress) * CGRectGetMaxY(containerView.bounds),
                                  CGRectGetWidth(containerView.bounds),
                                  CGRectGetHeight(containerView.bounds));
        
        self.dimmingView.alpha = progress;
    }
    else {
        UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        NSAssert(fromView != nil, @"Dismissed view must be available");
        fromView.frame = CGRectMake(0.f,
                                    progress * CGRectGetMaxY(containerView.bounds),
                                    CGRectGetWidth(containerView.bounds),
                                    CGRectGetHeight(containerView.bounds));
        
        self.dimmingView.alpha = 1.f - progress;
    }
}

- (void)completeTransition:(id<UIViewControllerContextTransitioning>)transitionContext success:(BOOL)success
{
    NSParameterAssert(transitionContext);
    
    // Appearance events need to be notified manually for custom transitions, see https://stackoverflow.com/a/29041911/760435
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (! success) {
        UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
        [toView removeFromSuperview];
        
        // Revert appearance transitions when cancelling so that lifecycle events are correctly balanced,
        // see https://stackoverflow.com/a/21309076/760435
        [toViewController beginAppearanceTransition:NO animated:transitionContext.animated];
        [fromViewController beginAppearanceTransition:YES animated:transitionContext.animated];
    }
    
    [fromViewController endAppearanceTransition];
    [toViewController endAppearanceTransition];
    
    [self.dimmingView removeFromSuperview];
    
    [transitionContext completeTransition:success];
}

#pragma mark Interactive transition

- (void)updateInteractiveTransitionWithProgress:(CGFloat)progress
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext updateInteractiveTransition:progress];
    [self updateTransition:self.transitionContext withProgress:progress];
}

- (void)cancelInteractiveTransition
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext cancelInteractiveTransition];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self updateTransition:self.transitionContext withProgress:0.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [self.transitionContext transitionWasCancelled];
        [self completeTransition:self.transitionContext success:success];
    }];
}

- (void)finishInteractiveTransition
{
    if (! self.transitionContext) {
        return;
    }
    
    [self.transitionContext finishInteractiveTransition];
    
    [UIView animateWithDuration:0.2 animations:^{
        [self updateTransition:self.transitionContext withProgress:1.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [self.transitionContext transitionWasCancelled];
        [self completeTransition:self.transitionContext success:success];
    }];
}

#pragma mark UIViewControllerAnimatedTransitioning protocol (non-interactive transition)

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    [self setupTransition:transitionContext];
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        [self updateTransition:transitionContext withProgress:1.f];
    } completion:^(BOOL finished) {
        BOOL success = ! [transitionContext transitionWasCancelled];
        [self completeTransition:transitionContext success:success];
    }];
}

#pragma mark UIViewControllerInteractiveTransitioning protocol (interactive transition)

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSParameterAssert(transitionContext);
    
    [self setupTransition:transitionContext];
    self.transitionContext = transitionContext;
}

- (UIViewAnimationCurve)completionCurve
{
    return UIViewAnimationCurveEaseInOut;
}

@end
