//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UICollectionView+PlaySRG.h"

@implementation UICollectionView (PlaySRG)

- (void)play_scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;
{
    @try {
        [self scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
    }
    @catch (NSException *exception) {}
}

@end
