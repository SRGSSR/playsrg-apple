//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SplitViewController.h"

@implementation SplitViewController

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.viewControllers.firstObject prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.viewControllers.firstObject preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.viewControllers.firstObject preferredStatusBarUpdateAnimation];
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    UIViewController *primaryViewController = self.viewControllers.firstObject;
    if ([primaryViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        UIViewController<PlayApplicationNavigation> *navigablePrimaryViewController = (UIViewController<PlayApplicationNavigation> *)primaryViewController;
        return [navigablePrimaryViewController openApplicationSectionInfo:applicationSectionInfo];
    }
    else {
        return NO;
    }
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    void (^performActiveTabAction)(UIViewController *) = ^(UIViewController *viewController) {
        if ([viewController conformsToProtocol:@protocol(TabBarActionable)]) {
            UIViewController<TabBarActionable> *actionableViewController = (UIViewController<TabBarActionable> *)viewController;
            [actionableViewController performActiveTabActionAnimated:animated];
        }
    };
    
    if (self.viewControllers.count == 2) {
        UIViewController *secondaryViewController = self.viewControllers[1];
        performActiveTabAction(secondaryViewController);
    }
    else {
        UIViewController *primaryViewController = self.viewControllers.firstObject;
        performActiveTabAction(primaryViewController);
    }
}

@end
