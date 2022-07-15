//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Orientation.h"

#import "UIDevice+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <objc/runtime.h>

static BOOL IsFullScreenCustomModalForOrientedViewController(UIViewController<Oriented> *viewController);
static NSArray<UIViewController *> *ChildViewControllersForOrientedViewController(UIViewController<Oriented> *viewController);
static UIInterfaceOrientationMask SupportedInterfaceOrientationsForOrientedViewController(UIViewController<Oriented> *viewController);
static UIInterfaceOrientationMask SupportedInterfaceOrientationsForViewController(UIViewController *viewController);

@implementation UIViewController (Orientation)

#pragma mark Class methods

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(supportedInterfaceOrientations)),
                                   class_getInstanceMethod(self, @selector(UIViewController_Orientation_swizzled_supportedInterfaceOrientations)));
}

#pragma mark Swizzled methods

- (UIInterfaceOrientationMask)UIViewController_Orientation_swizzled_supportedInterfaceOrientations
{
    // When a modal is presented with a custom style, the presenter is asked about supported orientations, which
    // implicitly assumes that most custom presentations only cover part of the screen. If the custom presentation
    // covers the whole screen, though, we should have similar behavior as `UIModalPresentationFullScreen`, i.e.
    // the presented view controller should be asked for supported orientations instead.
    UIViewController *presentedViewController = self.presentedViewController;
    if (presentedViewController.modalPresentationStyle == UIModalPresentationCustom && [presentedViewController conformsToProtocol:@protocol(Oriented)]) {
        UIViewController<Oriented> *orientedPresentedViewController = (UIViewController<Oriented> *)presentedViewController;
        if (IsFullScreenCustomModalForOrientedViewController(orientedPresentedViewController)) {
            return SupportedInterfaceOrientationsForOrientedViewController(orientedPresentedViewController);
        }
    }
    
    return SupportedInterfaceOrientationsForViewController(self);
}

#pragma mark Public methods

- (BOOL)play_supportsOrientation:(UIInterfaceOrientation)orientation
{
    return (SupportedInterfaceOrientationsForViewController(self) & (1 << orientation)) != 0;
}

- (void)play_presentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion
{
    // Not animated: The system takes care of sending transition appearance events (and thus view lifecycle events).
    // Custom transition: Retrieved from the delegate only when animated. Must take care of implementing transition
    //                    appearance events (most notably for interactive transitions which otherwise would not be
    //                    covered).
    if (animated || ! viewController.transitioningDelegate) {
        [self presentViewController:viewController animated:YES completion:completion];
    }
    else {
        UIViewController *fromViewController = self;
        UIViewController *toViewController = viewController;
        
        [fromViewController beginAppearanceTransition:NO animated:NO];
        [toViewController beginAppearanceTransition:YES animated:NO];
        
        [self presentViewController:viewController animated:NO completion:^{
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
            
            completion ? completion() : nil;
        }];
    }
}

- (void)play_dismissViewControllerAnimated:(BOOL)animated completion:(void (^)(void))completion
{
#if TARGET_OS_IOS
    UIViewController *topViewController = self.play_topViewController;
    
    // See https://stackoverflow.com/a/29560217
    UIViewController *presentingViewController = topViewController.presentingViewController;
    if (! [presentingViewController play_supportsOrientation:(UIInterfaceOrientation)UIDevice.currentDevice.orientation]) {
        if ([presentingViewController play_supportsOrientation:UIInterfaceOrientationPortrait]) {
            [UIDevice.currentDevice rotateToUserInterfaceOrientation:UIInterfaceOrientationPortrait];
        }
        else if ([presentingViewController play_supportsOrientation:UIInterfaceOrientationPortraitUpsideDown]) {
            [UIDevice.currentDevice rotateToUserInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown];
        }
        else if ([presentingViewController play_supportsOrientation:UIInterfaceOrientationLandscapeLeft]) {
            [UIDevice.currentDevice rotateToUserInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        }
        else if ([presentingViewController play_supportsOrientation:UIInterfaceOrientationLandscapeRight]) {
            [UIDevice.currentDevice rotateToUserInterfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
    }
#endif
    
    // See `-play_presentViewController:animated:completion:`
    if (animated || ! self.transitioningDelegate) {
        [self dismissViewControllerAnimated:animated completion:completion];
    }
    else {
        UIViewController *fromViewController = self;
        UIViewController *toViewController = self.presentingViewController;
        
        [fromViewController beginAppearanceTransition:NO animated:NO];
        [toViewController beginAppearanceTransition:YES animated:NO];
        
        [self dismissViewControllerAnimated:NO completion:^{
            [fromViewController endAppearanceTransition];
            [toViewController endAppearanceTransition];
            
            completion ? completion() : nil;
        }];
    }
}

@end

static BOOL IsFullScreenCustomModalForOrientedViewController(UIViewController<Oriented> *viewController)
{
    if ([viewController respondsToSelector:@selector(play_isFullScreenWhenDisplayedInCustomModal)]) {
        return [viewController play_isFullScreenWhenDisplayedInCustomModal];
    }
    else {
        return NO;
    }
}

static NSArray<UIViewController *> *ChildViewControllersForOrientedViewController(UIViewController<Oriented> *viewController)
{
    if ([viewController respondsToSelector:@selector(play_orientingChildViewControllers)]) {
        return [viewController play_orientingChildViewControllers];
    }
    else {
        return @[];
    }
}

static UIInterfaceOrientationMask SupportedInterfaceOrientationsForOrientedViewController(UIViewController<Oriented> *viewController)
{
    if ([viewController respondsToSelector:@selector(play_supportedInterfaceOrientations)]) {
        return [viewController play_supportedInterfaceOrientations];
    }
    else if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

static UIInterfaceOrientationMask SupportedInterfaceOrientationsForViewController(UIViewController *viewController)
{
    // For `Oriented` view controllers we can determine the overall orientation support by combining the intrinsic
    // rotation behavior of the view controller with the one of its participating children.
    if ([viewController conformsToProtocol:@protocol(Oriented)]) {
        UIViewController<Oriented> *orientedViewController = (UIViewController<Oriented> *)viewController;
        UIInterfaceOrientationMask supportedInterfaceOrientations = SupportedInterfaceOrientationsForOrientedViewController(orientedViewController);
        for (UIViewController *viewController in ChildViewControllersForOrientedViewController(orientedViewController)) {
            supportedInterfaceOrientations &= SupportedInterfaceOrientationsForViewController(viewController);
        }
        return supportedInterfaceOrientations;
    }
    else {
        return [viewController UIViewController_Orientation_swizzled_supportedInterfaceOrientations];
    }
}
