//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

#import "UIView+PlaySRG.h"

@implementation UIScrollView (PlaySRG)

+ (BOOL)canDisplayLargeTitleInViewController:(UIViewController *)viewController
{
    UINavigationBar *navigationBar = viewController.navigationController.navigationBar;
    return (navigationBar && ! navigationBar.hidden && navigationBar.prefersLargeTitles
            && viewController.navigationItem.largeTitleDisplayMode != UINavigationItemLargeTitleDisplayModeNever);
}

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    // To reveal a large navigation bar if it can be displayed, we have to scroll just a tiny bit before the top
    // (1 px suffices) so that the large title is forced to be displayed.
    UIViewController *nearestViewController = self.play_nearestViewController;
    CGFloat navigationBarOffset = [UIScrollView canDisplayLargeTitleInViewController:nearestViewController] ? 1.f : 0.f;
    [self setContentOffset:CGPointMake(self.contentOffset.x, -self.adjustedContentInset.top - navigationBarOffset) animated:animated];
}

@end
