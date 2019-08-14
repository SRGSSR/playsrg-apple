//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

@implementation UIScrollView (PlaySRG)

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    if (@available(iOS 11, *)) {
        [self setContentOffset:CGPointMake(0.f, -self.adjustedContentInset.top) animated:animated];
    }
    else {
        [self setContentOffset:CGPointMake(0.f, -self.contentInset.top) animated:animated];
    }
}

@end
