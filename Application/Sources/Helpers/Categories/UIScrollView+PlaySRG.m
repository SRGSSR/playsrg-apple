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

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    CGFloat topAdjustedContentInset = self.adjustedContentInset.top;
    
    // Scroll view not covered by bars and requiring no adjustment. To reveal a large title it suffices to scroll just a tiny
    // bit before the top content offset (1 px is enough)
    if (topAdjustedContentInset == 0.f) {
        CGFloat navigationBarOffset = [self play_canDisplayLargeTitle] ? 1.f : 0.f;
        [self setContentOffset:CGPointMake(self.contentOffset.x, -topAdjustedContentInset - navigationBarOffset) animated:animated];
    }
    // Scroll view covered by bars. To reveal a large title we must scroll before the top content offset, with a distance
    // equal to the (undocumented) large title added height (52 px, see https://ivomynttinen.com/blog/ios-design-guidelines)
    else if (self.contentOffset.y > -topAdjustedContentInset) {
        CGFloat navigationBarOffset = [self play_canDisplayLargeTitle] ? 52.f : 0.f;
        [self setContentOffset:CGPointMake(self.contentOffset.x, -topAdjustedContentInset - navigationBarOffset) animated:animated];
    }
}

@end
