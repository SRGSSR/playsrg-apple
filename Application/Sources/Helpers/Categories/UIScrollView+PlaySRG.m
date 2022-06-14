//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

#import "UIView+PlaySRG.h"

static const CGFloat kSearchBarHeightContribution = 52.f;
static const CGFloat kLargeNavigationBarHeightContribution = 52.f;

@implementation UIScrollView (PlaySRG)

+ (UINavigationController *)play_topmostNavigationControllerFromViewController:(UIViewController *)viewController
{
    UINavigationController *navigationController = viewController.navigationController;
    if (navigationController) {
        return [self play_topmostNavigationControllerFromViewController:navigationController];
    }
    else if ([viewController isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)viewController;
    }
    else {
        return nil;
    }
}

- (BOOL)play_canExpandToLargeNavigation
{
    UIViewController *nearestViewController = self.play_nearestViewController;
    UINavigationItem *navigationItem = nearestViewController.navigationItem;
    
    CGFloat collapsedHeight = navigationItem.searchController ? kLargeNavigationBarHeightContribution + kSearchBarHeightContribution : kLargeNavigationBarHeightContribution;
    UINavigationController *navigationController = [UIScrollView play_topmostNavigationControllerFromViewController:nearestViewController];
    UINavigationBar *navigationBar = navigationController.navigationBar;
    return (navigationBar && ! navigationController.navigationBarHidden && navigationBar.prefersLargeTitles && CGRectGetHeight(navigationBar.frame) <= collapsedHeight
            && navigationItem.largeTitleDisplayMode != UINavigationItemLargeTitleDisplayModeNever);
}

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    CGFloat topAdjustedContentInset = self.adjustedContentInset.top;
    
    // Scroll view not covered by bars and requiring no adjustment. To reveal a large title it suffices to scroll just a tiny
    // bit before the top content offset (1 px is enough)
    if (topAdjustedContentInset == 0.f) {
        CGFloat navigationBarOffset = [self play_canExpandToLargeNavigation] ? 1.f : 0.f;
        [self setContentOffset:CGPointMake(self.contentOffset.x, -topAdjustedContentInset - navigationBarOffset) animated:animated];
    }
    // Scroll view covered by bars. To reveal a large title we must scroll before the top content offset, with a distance
    // equal to the (undocumented) large title added height (52 px, see https://ivomynttinen.com/blog/ios-design-guidelines)
    else if (self.contentOffset.y > -topAdjustedContentInset) {
        CGFloat navigationBarOffset = [self play_canExpandToLargeNavigation] ? kLargeNavigationBarHeightContribution : 0.f;
        [self setContentOffset:CGPointMake(self.contentOffset.x, -topAdjustedContentInset - navigationBarOffset) animated:animated];
    }
}

@end
