//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIWindow+PlaySRG.h"

@implementation UIWindow (PlaySRG)

- (UIViewController *)play_topViewController
{
    UIViewController *topViewController = self.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    return topViewController;
}

- (void)play_dismissAllViewControllersAnimated:(BOOL)animated completion:(void (^)(void))completion
{
    [self.rootViewController dismissViewControllerAnimated:animated completion:completion];
}

@end
