//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Calculate the width to apply to items within a grid so that they approach some desired size, ensuring constant spacing
 *  between items.
 *
 *  @param itemApproximateWidth The desired approximate width for items. The returned width might be smaller or bigger.
 *  @param layoutWidth          The total available width.
 *  @param leadingInset         The leading layout inset.
 *  @param trailingInset        The trailing layout inset.
 *  @param spacing              The desired spacing.
 */
OBJC_EXPORT CGFloat GridLayoutOptimalItemWidth(CGFloat itemApproximateWidth, CGFloat layoutWidth, CGFloat leadingInset, CGFloat trailingInset, CGFloat spacing);

/**
 *  Standard media cell (16:9 artwork + text area) size for grid layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 *  @param large     Large layout (e.g. featured).
 */
OBJC_EXPORT CGSize GridLayoutMediaStandardItemSize(CGFloat itemWidth, BOOL large);

/**
 *  Live media cell (16:9 artwork + text area) size for grid layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 */
OBJC_EXPORT CGSize GridLayoutLiveMediaStandardItemSize(CGFloat itemWidth);

/**
 *  Standard media cell (16:9 artwork + text area) size for grid layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 *  @param large     Large layout (e.g. featured).
 */
OBJC_EXPORT CGSize GridLayoutShowStandardItemSize(CGFloat itemWidth, BOOL large);

NS_ASSUME_NONNULL_END
