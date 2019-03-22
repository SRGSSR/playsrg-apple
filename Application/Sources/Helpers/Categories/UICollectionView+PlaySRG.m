//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UICollectionView+PlaySRG.h"

@implementation UICollectionView (PlaySRG)

- (CGPoint)play_maximumContentOffset
{
    return CGPointMake(fmaxf(self.contentSize.width - CGRectGetWidth(self.frame), 0.f),
                       fmaxf(self.contentSize.height - CGRectGetHeight(self.frame), 0.f));
}

@end
