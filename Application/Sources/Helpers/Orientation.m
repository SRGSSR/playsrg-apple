//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Orientation.h"

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
    return (self.supportedInterfaceOrientations & (1 << orientation)) != 0;
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
