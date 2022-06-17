//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

#import "Layout.h"
#import "UIView+PlaySRG.h"

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
    UINavigationController *navigationController = [UIScrollView play_topmostNavigationControllerFromViewController:nearestViewController];
    return LayoutNavigationBarStateForNavigationController(navigationController) == LayoutNavigationBarStateLargeCollapsed;
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
        CGFloat navigationBarOffset = [self play_canExpandToLargeNavigation] ? LayoutLargeNavigationBarHeightContribution : 0.f;
        [self setContentOffset:CGPointMake(self.contentOffset.x, -topAdjustedContentInset - navigationBarOffset) animated:animated];
    }
}

@end
