//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TabStrip.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Cell for tab bar display by the `TabStrip` control.
 */
@interface TabStripCell : UICollectionViewCell

/**
 *  Return the recommended intrinsic width calculated for a given item and constrained to the specified height.
 */
+ (CGFloat)widthForItem:(PageItem *)item withHeight:(CGFloat)height;

/**
 *  The item to display.
 */
@property (nonatomic, nullable) PageItem *item;

/**
 *  Set `YES` to highlight the item as current one.
 */
@property (nonatomic, getter=isCurrent) BOOL current;

@end

NS_ASSUME_NONNULL_END
