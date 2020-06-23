//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIScrollView+PlaySRG.h"

@implementation UIScrollView (PlaySRG)

- (void)play_scrollToTopAnimated:(BOOL)animated
{
    [self setContentOffset:CGPointMake(0.f, -self.adjustedContentInset.top) animated:animated];
}

@end
