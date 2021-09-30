//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UICollectionView (PlaySRG)

/**
 *  Same as `-scrollToItemAtIndexPath:atScrollPosition:animated:` but inhibiting assertions.
 */
- (void)play_scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
