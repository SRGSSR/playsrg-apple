//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

#import "UIView+PlaySRG.h"

@implementation UIScrollView (PlaySRG)

- (BOOL)play_canDisplayLargeTitle
{
    UIViewController *nearestViewController = self.play_nearestViewController;
    UINavigationBar *navigationBar = nearestViewController.navigationController.navigationBar;
    return (navigationBar && ! navigationBar.hidden && navigationBar.prefersLargeTitles
            && nearestViewController.navigationItem.largeTitleDisplayMode != UINavigationItemLargeTitleDisplayModeNever);
}

- (BOOL)play_isContainedInNavigationController
{
    UIViewController *nearestViewController = self.play_nearestViewController;
    return nearestViewController.parentViewController == nearestViewController.navigationController;
}

- (CGFloat)play_navigationBarOffset
{
    if ([self play_canDisplayLargeTitle]) {
        // 52 px is the additional height associated with large titles, see https://ivomynttinen.com/blog/ios-design-guidelines
        if ([self play_isContainedInNavigationController]) {
            return 52.f;
        }
        // To reveal a large navigation bar if it can be displayed, we have to scroll just a tiny bit before the top
        // (1 px suffices) so that the large title is forced to be displayed.
        else {
            return 1.f;
        }
    }
    else {
        return 0.f;
    }
}

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    [self setContentOffset:CGPointMake(self.contentOffset.x, -self.adjustedContentInset.top - [self play_navigationBarOffset]) animated:animated];
}

@end
