//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard corner radius constants.
 */
static const CGFloat LayoutStandardLabelCornerRadius = 2.f;
static const CGFloat LayoutStandardViewCornerRadius = 4.f;

/**
 *  Standard cell dimensions.
 */
static const CGFloat LayoutCollectionViewCellStandardWidth = 210.f;
static const CGFloat LayoutTableViewCellStandardHeight = 84.f;

/**
 *  Standard table view padding.
 */
static const UIEdgeInsets LayoutStandardTableViewPaddingInsets = { 10.f, 0.f, 5.f, 0.f };

/**
 *  Standard margin.
 */
static const CGFloat LayoutStandardMargin = 10.f;

/**
 *  Calculate the width to apply to items within a collection so that they approach some desired size, ensuring constant
 *  spacing between items.
 *
 *  @param itemApproximateWidth The desired approximate width for items. The returned width might be smaller or bigger.
 *  @param layoutWidth          The total available width for layout.
 *  @param leadingInset         The leading layout inset.
 *  @param trailingInset        The trailing layout inset.
 *  @param spacing              The desired spacing.
 */
OBJC_EXPORT CGFloat LayoutCollectionItemOptimalWidth(CGFloat itemApproximateWidth, CGFloat layoutWidth, CGFloat leadingInset, CGFloat trailingInset, CGFloat spacing);

/**
 *  Calculate the width to apply to featured items in a collection. Featured items attempt occupying (almost) the full width
 *  of narrow layouts, but still have bounded (larger) size on wide layouts.
 *
 *  @param layoutWidth The total available width for layout.
 */
OBJC_EXPORT CGFloat LayoutCollectionItemFeaturedWidth(CGFloat layoutWidth);

/**
 *  Return the standard height for table view headers.
 */
OBJC_EXPORT CGFloat LayoutStandardTableSectionHeaderHeight(void);

/**
 *  Standard media cell (16:9 artwork + text area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 *  @param large     Large layout (e.g. featured).
 */
OBJC_EXPORT CGSize LayoutMediaStandardCollectionItemSize(CGFloat itemWidth, BOOL large);

/**
 *  Live media cell (16:9 artwork + text area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 */
OBJC_EXPORT CGSize LayoutLiveMediaStandardCollectionItemSize(CGFloat itemWidth);

/**
 *  Standard media cell (16:9 artwork + text area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 *  @param large     Large layout (e.g. featured).
 */
OBJC_EXPORT CGSize LayoutShowStandardCollectionItemSize(CGFloat itemWidth, BOOL large);

NS_ASSUME_NONNULL_END
