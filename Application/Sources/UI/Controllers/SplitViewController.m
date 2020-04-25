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

@end
